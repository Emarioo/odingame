package game

// import "../cgltf"
import "vendor:cgltf"
import "core:fmt"
import "core:strings"
import "core:os"
import "core:path/filepath"
import "core:slice"
import "core:math/linalg/glsl"
import "core:math"
import "core:mem"
import "core:c"
import "base:runtime"
import "core:time"


Vertex :: struct {
    // See object.glsl shader
    pos : vec3,
    normal : vec3,
    texcoord : vec2,
}   

Material :: struct {
    diffuse : vec3,
    // specular : vec3,
    base_texture: Texture,
}

Mesh :: struct {
    vao, vbo, ibo: u32,
    index_count: i32,

    material: Material,
    vertices : []Vertex,
    indices : []u32,
}

Model :: struct {
    // scene : ^ai.aiScene,
    raw_data : ^cgltf.data,
    meshes : [dynamic]Mesh,
}


override_file_read :: proc "c" (memory_options: ^cgltf.memory_options, file_options: ^cgltf.file_options, path: cstring, size: ^uint, data: ^rawptr) -> cgltf.result {
    context = (cast(^runtime.Context)file_options.user_data)^
    
    filepath := string(path)
    file_data, ok := os.read_entire_file(filepath)
    if !ok {
        return .file_not_found
    }
    
    size^ = len(file_data)
    data^ = transmute(rawptr)raw_data(file_data)
    
    return .success
}

override_file_release :: proc "c" (memory_options: ^cgltf.memory_options, file_options: ^cgltf.file_options, data: rawptr) {
    context = (cast(^runtime.Context)file_options.user_data)^

    bytes := slice.bytes_from_ptr(data, 0)
    delete(bytes)
}


load_model :: proc (path : string) -> (model: Model) {
    cpath := strings.unsafe_string_to_cstring(path)
    options: cgltf.options
    c: runtime.Context = context
    options.file.user_data = &c
    options.file.read = override_file_read
    options.file.release = override_file_release
    data, result := cgltf.parse_file(options, cpath)

    if result != .success {
        fmt.printfln("cgltf failed, could not parse %v", path)
        return
    }

    result = cgltf.load_buffers(options, data, cpath)
    if result != .success {
        fmt.printfln("cgltf failed, could not load buffers %v", path)
        return
    }

    model.raw_data = data

    scene := data.scenes[0]
    node := scene.nodes[0]
    mesh := node.mesh

    for pi in 0..<len(mesh.primitives) {
        primitive := &mesh.primitives[pi]

        assert(primitive.type == .triangles)
        assert(primitive.attributes[0].type == .position)
        assert(primitive.attributes[1].type == .normal)
        assert(primitive.attributes[0].data.count == primitive.attributes[1].data.count)
        assert(primitive.attributes[0].data.component_type == .r_32f)
        assert(primitive.attributes[1].data.component_type == .r_32f)
        assert(primitive.indices.component_type == .r_16u)
        
        vertex_count := primitive.attributes[0].data.count
        index_count := primitive.indices.count
        vertices := make([]Vertex, vertex_count)
        indices  := make([]u32, index_count)
        
        // We assume POSITION is attribute[0]
        // We assume NORMAL is attribute[1]
        // We assume TEXCOORD0 is attribute[2]
        // We assume TEXCOORDn is attribute[2+n]
        position_acc   := primitive.attributes[0].data
        normal_acc     := primitive.attributes[1].data
        texcoord_acc   : ^cgltf.accessor
        if primitive.material.has_pbr_metallic_roughness {
            index := 2 + primitive.material.pbr_metallic_roughness.base_color_texture.texcoord
            assert(primitive.attributes[index].type == cgltf.attribute_type.texcoord)
            fmt.printfln("tex %v %v", primitive.material.name, primitive.material.pbr_metallic_roughness.base_color_texture.texcoord)
            texcoord_acc = primitive.attributes[index].data
        }
        
        for j in 0..<vertex_count {
            res := cgltf.accessor_read_float(position_acc, j, cast([^]f32)&vertices[j].pos, 3)
            res = cgltf.accessor_read_float(normal_acc, j, cast([^]f32)&vertices[j].normal, 3)
            if texcoord_acc != nil {
                res = cgltf.accessor_read_float(texcoord_acc, j, cast([^]f32)&vertices[j].texcoord, 2)
                // Needed if load_texture flips the texture on load.
                // load_texture currently flips the texture because drawing images are upside-down otherwise.
                // Do we want to move this quirk into the shaders instead?
                vertices[j].texcoord.y = 1 - vertices[j].texcoord.y
            }
        }
        index_acc := primitive.indices
        for j in 0..<index_count {
            indices[j] = cast(u32)cgltf.accessor_read_index(index_acc, j)
        }

        material: Material

        if primitive.material.has_pbr_metallic_roughness {
            bytes := slice.from_ptr(cast(^u8)mem.ptr_offset(cast(^u8)primitive.material.pbr_metallic_roughness.base_color_texture.texture.image_.buffer_view.buffer.data, primitive.material.pbr_metallic_roughness.base_color_texture.texture.image_.buffer_view.offset), cast(int) primitive.material.pbr_metallic_roughness.base_color_texture.texture.image_.buffer_view.size)
            material.base_texture = load_texture(bytes)
        }

        // material.diffuse_color = {1,1,1}
        // material.specular_color

        // fmt.printfln("append mesh %v, %v, %v", primitive.name, vertex_count, index_count)

        f32_vertices := slice.from_ptr(cast(^f32)slice.first_ptr(vertices), len(vertices) * size_of(Vertex) / size_of(f32))

        append(&model.meshes, create_mesh(f32_vertices, indices, material))
        // append(&model.meshes, create_mesh(f32_vertices, indices, material))
    }

    // cgltf.free(data)
    fmt.printfln("Loaded model '%v'", path)

    return
}


/*

import ai "lib:assimp"

load_model :: proc (path : string) -> (model: Model) {
    
    model.scene = ai.aiImportFile(strings.unsafe_string_to_cstring(path), cast(u32)ai.aiPostProcessSteps.aiProcess_MakeLeftHanded |
        cast(u32)ai.aiPostProcessSteps.aiProcess_Triangulate
    )

    if model.scene == nil {
        fmt.eprintln("Could not load",path, ", error:",ai.aiGetErrorString());
        os.exit(1)
    }

    assert(1 <= model.scene.mRootNode.mNumMeshes)
    
    mesh_index := model.scene.mRootNode.mMeshes[0]

    assert(mesh_index < model.scene.mNumMeshes)
    mesh : ^ai.aiMesh = model.scene.mMeshes[mesh_index]

    Vertex :: struct {
        // See object.glsl shader
        pos : vec3,
        normal : vec3,
        texture : vec3,
    }   

    vertices := make([]Vertex, mesh.mNumVertices * size_of(Vertex) / size_of(f32))
    indices  := make([]u32, mesh.mNumFaces * 3)

    for i in 0..<mesh.mNumVertices {
        vertices[i].pos = mesh.mVertices[i]
    }
    if mesh.mNormals != nil {
        for i in 0..<mesh.mNumVertices {
            vertices[i].normal = mesh.mNormals[i]
        }
    }
    if mesh.mTextureCoords[0] != nil {
        assert(mesh.mNumUVComponents[0] == 2)
        for i in 0..<mesh.mNumVertices {
            vertices[i].texture.xy = mesh.mTextureCoords[0][i].xy
            vertices[i].texture.z = 0.0 // local material index (used in shader, uMaterials[0])
        }
    }

    fmt.printfln("vertex %v", mesh.mNumVertices)
    fmt.printfln("faces %v", mesh.mNumFaces)
    for i in 0..<mesh.mNumFaces {
        // Seems like assimp and opengl has different
        // order for which is the front of the face (clockwise vs counter clockwise)
        indices[3*i + 0] = mesh.mFaces[i].mIndices[2]
        indices[3*i + 1] = mesh.mFaces[i].mIndices[1]
        indices[3*i + 2] = mesh.mFaces[i].mIndices[0]
    }

    f32_vertices := slice.from_ptr(cast(^f32) slice.first_ptr(vertices), len(vertices) * size_of(Vertex) / size_of(f32))
    model.mesh = create_mesh(f32_vertices, indices)

    fmt.printf("Loaded model '%s'\n", path)

    return
}
*/