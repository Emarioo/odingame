/**
 * cgltf - a single-file glTF 2.0 parser written in C99.
 *
 * Version: 1.15
 *
 * Website: https://github.com/jkuhlmann/cgltf
 *
 * Distributed under the MIT License, see notice at the end of this file.
 *
 * Building:
 * Include this file where you need the struct and function
 * declarations. Have exactly one source file where you define
 * `CGLTF_IMPLEMENTATION` before including this file to get the
 * function definitions.
 *
 * Reference:
 * `cgltf_result cgltf_parse(const cgltf_options*, const void*,
 * cgltf_size, cgltf_data**)` parses both glTF and GLB data. If
 * this function returns `cgltf_result_success`, you have to call
 * `cgltf_free()` on the created `cgltf_data*` variable.
 * Note that contents of external files for buffers and images are not
 * automatically loaded. You'll need to read these files yourself using
 * URIs in the `cgltf_data` structure.
 *
 * `cgltf_options` is the struct passed to `cgltf_parse()` to control
 * parts of the parsing process. You can use it to force the file type
 * and provide memory allocation as well as file operation callbacks.
 * Should be zero-initialized to trigger default behavior.
 *
 * `cgltf_data` is the struct allocated and filled by `cgltf_parse()`.
 * It generally mirrors the glTF format as described by the spec (see
 * https://github.com/KhronosGroup/glTF/tree/master/specification/2.0).
 *
 * `void cgltf_free(cgltf_data*)` frees the allocated `cgltf_data`
 * variable.
 *
 * `cgltf_result cgltf_load_buffers(const cgltf_options*, cgltf_data*,
 * const char* gltf_path)` can be optionally called to open and read buffer
 * files using the `FILE*` APIs. The `gltf_path` argument is the path to
 * the original glTF file, which allows the parser to resolve the path to
 * buffer files.
 *
 * `cgltf_result cgltf_load_buffer_base64(const cgltf_options* options,
 * cgltf_size size, const char* base64, void** out_data)` decodes
 * base64-encoded data content. Used internally by `cgltf_load_buffers()`.
 * This is useful when decoding data URIs in images.
 *
 * `cgltf_result cgltf_parse_file(const cgltf_options* options, const
 * char* path, cgltf_data** out_data)` can be used to open the given
 * file using `FILE*` APIs and parse the data using `cgltf_parse()`.
 *
 * `cgltf_result cgltf_validate(cgltf_data*)` can be used to do additional
 * checks to make sure the parsed glTF data is valid.
 *
 * `cgltf_node_transform_local` converts the translation / rotation / scale properties of a node
 * into a mat4.
 *
 * `cgltf_node_transform_world` calls `cgltf_node_transform_local` on every ancestor in order
 * to compute the root-to-node transformation.
 *
 * `cgltf_accessor_unpack_floats` reads in the data from an accessor, applies sparse data (if any),
 * and converts them to floating point. Assumes that `cgltf_load_buffers` has already been called.
 * By passing null for the output pointer, users can find out how many floats are required in the
 * output buffer.
 *
 * `cgltf_accessor_unpack_indices` reads in the index data from an accessor. Assumes that
 * `cgltf_load_buffers` has already been called. By passing null for the output pointer, users can
 * find out how many indices are required in the output buffer. Returns 0 if the accessor is
 * sparse or if the output component size is less than the accessor's component size.
 *
 * `cgltf_num_components` is a tiny utility that tells you the dimensionality of
 * a certain accessor type. This can be used before `cgltf_accessor_unpack_floats` to help allocate
 * the necessary amount of memory. `cgltf_component_size` and `cgltf_calc_size` exist for
 * similar purposes.
 *
 * `cgltf_accessor_read_float` reads a certain element from a non-sparse accessor and converts it to
 * floating point, assuming that `cgltf_load_buffers` has already been called. The passed-in element
 * size is the number of floats in the output buffer, which should be in the range [1, 16]. Returns
 * false if the passed-in element_size is too small, or if the accessor is sparse.
 *
 * `cgltf_accessor_read_uint` is similar to its floating-point counterpart, but limited to reading
 * vector types and does not support matrix types. The passed-in element size is the number of uints
 * in the output buffer, which should be in the range [1, 4]. Returns false if the passed-in
 * element_size is too small, or if the accessor is sparse.
 *
 * `cgltf_accessor_read_index` is similar to its floating-point counterpart, but it returns size_t
 * and only works with single-component data types.
 *
 * `cgltf_copy_extras_json` allows users to retrieve the "extras" data that can be attached to many
 * glTF objects (which can be arbitrary JSON data). This is a legacy function, consider using
 * cgltf_extras::data directly instead. You can parse this data using your own JSON parser
 * or, if you've included the cgltf implementation using the integrated JSMN JSON parser.
 */
package cgltf

import "core:c"

foreign import lib "cgltf.lib"
_ :: lib

cgltf_size  :: c.size_t
cgltf_ssize :: i64
cgltf_float :: f32
cgltf_int   :: i32
cgltf_uint  :: u32
cgltf_bool  :: i32

cgltf_file_type :: enum i32 {
	invalid  = 0,
	gltf     = 1,
	glb      = 2,
	max_enum = 3,
}

cgltf_result :: enum i32 {
	success         = 0,
	data_too_short  = 1,
	unknown_format  = 2,
	invalid_json    = 3,
	invalid_gltf    = 4,
	invalid_options = 5,
	file_not_found  = 6,
	io_error        = 7,
	out_of_memory   = 8,
	legacy_gltf     = 9,
	max_enum        = 10,
}

cgltf_memory_options :: struct {
	alloc_func: proc "c" (user: rawptr, size: cgltf_size) -> rawptr,
	free_func:  proc "c" (user: rawptr, ptr: rawptr),
	user_data:  rawptr,
}

cgltf_file_options :: struct {
	read:      proc "c" (memory_options: ^cgltf_memory_options, file_options: ^cgltf_file_options, path: cstring, size: ^cgltf_size, data: ^rawptr) -> cgltf_result,
	release:   proc "c" (memory_options: ^cgltf_memory_options, file_options: ^cgltf_file_options, data: rawptr, size: cgltf_size),
	user_data: rawptr,
}

cgltf_options :: struct {
	type:             cgltf_file_type, /* invalid == auto detect */
	json_token_count: cgltf_size,      /* 0 == auto */
	memory:           cgltf_memory_options,
	file:             cgltf_file_options,
}

cgltf_buffer_view_type :: enum i32 {
	invalid  = 0,
	indices  = 1,
	vertices = 2,
	max_enum = 3,
}

cgltf_attribute_type :: enum i32 {
	invalid  = 0,
	position = 1,
	normal   = 2,
	tangent  = 3,
	texcoord = 4,
	color    = 5,
	joints   = 6,
	weights  = 7,
	custom   = 8,
	max_enum = 9,
}

cgltf_component_type :: enum i32 {
	invalid  = 0,
	r_8      = 1, /* BYTE */
	r_8u     = 2, /* UNSIGNED_BYTE */
	r_16     = 3, /* SHORT */
	r_16u    = 4, /* UNSIGNED_SHORT */
	r_32u    = 5, /* UNSIGNED_INT */
	r_32f    = 6, /* FLOAT */
	max_enum = 7,
}

cgltf_type :: enum i32 {
	invalid  = 0,
	scalar   = 1,
	vec2     = 2,
	vec3     = 3,
	vec4     = 4,
	mat2     = 5,
	mat3     = 6,
	mat4     = 7,
	max_enum = 8,
}

cgltf_primitive_type :: enum i32 {
	invalid        = 0,
	points         = 1,
	lines          = 2,
	line_loop      = 3,
	line_strip     = 4,
	triangles      = 5,
	triangle_strip = 6,
	triangle_fan   = 7,
	max_enum       = 8,
}

cgltf_alpha_mode :: enum i32 {
	opaque   = 0,
	mask     = 1,
	blend    = 2,
	max_enum = 3,
}

cgltf_animation_path_type :: enum i32 {
	invalid     = 0,
	translation = 1,
	rotation    = 2,
	scale       = 3,
	weights     = 4,
	max_enum    = 5,
}

cgltf_interpolation_type :: enum i32 {
	linear       = 0,
	step         = 1,
	cubic_spline = 2,
	max_enum     = 3,
}

cgltf_camera_type :: enum i32 {
	invalid      = 0,
	perspective  = 1,
	orthographic = 2,
	max_enum     = 3,
}

cgltf_light_type :: enum i32 {
	invalid     = 0,
	directional = 1,
	point       = 2,
	spot        = 3,
	max_enum    = 4,
}

cgltf_data_free_method :: enum i32 {
	none         = 0,
	file_release = 1,
	memory_free  = 2,
	max_enum     = 3,
}

cgltf_extras :: struct {
	start_offset: cgltf_size, /* this field is deprecated and will be removed in the future; use data instead */
	end_offset:   cgltf_size, /* this field is deprecated and will be removed in the future; use data instead */
	data:         cstring,
}

cgltf_extension :: struct {
	name: cstring,
	data: cstring,
}

cgltf_buffer :: struct {
	name:             cstring,
	size:             cgltf_size,
	uri:              cstring,
	data:             rawptr, /* loaded by cgltf_load_buffers */
	data_free_method: cgltf_data_free_method,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_meshopt_compression_mode :: enum i32 {
	invalid    = 0,
	attributes = 1,
	triangles  = 2,
	indices    = 3,
	max_enum   = 4,
}

cgltf_meshopt_compression_filter :: enum i32 {
	none        = 0,
	octahedral  = 1,
	quaternion  = 2,
	exponential = 3,
	max_enum    = 4,
}

cgltf_meshopt_compression :: struct {
	buffer: ^cgltf_buffer,
	offset: cgltf_size,
	size:   cgltf_size,
	stride: cgltf_size,
	count:  cgltf_size,
	mode:   cgltf_meshopt_compression_mode,
	filter: cgltf_meshopt_compression_filter,
}

cgltf_buffer_view :: struct {
	name:                    cstring,
	buffer:                  ^cgltf_buffer,
	offset:                  cgltf_size,
	size:                    cgltf_size,
	stride:                  cgltf_size, /* 0 == automatically determined by accessor */
	type:                    cgltf_buffer_view_type,
	data:                    rawptr,     /* overrides buffer->data if present, filled by extensions */
	has_meshopt_compression: cgltf_bool,
	meshopt_compression:     cgltf_meshopt_compression,
	extras:                  cgltf_extras,
	extensions_count:        cgltf_size,
	extensions:              ^cgltf_extension,
}

cgltf_accessor_sparse :: struct {
	count:                  cgltf_size,
	indices_buffer_view:    ^cgltf_buffer_view,
	indices_byte_offset:    cgltf_size,
	indices_component_type: cgltf_component_type,
	values_buffer_view:     ^cgltf_buffer_view,
	values_byte_offset:     cgltf_size,
}

cgltf_accessor :: struct {
	name:             cstring,
	component_type:   cgltf_component_type,
	normalized:       cgltf_bool,
	type:             cgltf_type,
	offset:           cgltf_size,
	count:            cgltf_size,
	stride:           cgltf_size,
	buffer_view:      ^cgltf_buffer_view,
	has_min:          cgltf_bool,
	min:              [16]cgltf_float,
	has_max:          cgltf_bool,
	max:              [16]cgltf_float,
	is_sparse:        cgltf_bool,
	sparse:           cgltf_accessor_sparse,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_attribute :: struct {
	name:  cstring,
	type:  cgltf_attribute_type,
	index: cgltf_int,
	data:  ^cgltf_accessor,
}

cgltf_image :: struct {
	name:             cstring,
	uri:              cstring,
	buffer_view:      ^cgltf_buffer_view,
	mime_type:        cstring,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_filter_type :: enum i32 {
	undefined              = 0,
	nearest                = 9728,
	linear                 = 9729,
	nearest_mipmap_nearest = 9984,
	linear_mipmap_nearest  = 9985,
	nearest_mipmap_linear  = 9986,
	linear_mipmap_linear   = 9987,
}

cgltf_wrap_mode :: enum i32 {
	clamp_to_edge   = 33071,
	mirrored_repeat = 33648,
	repeat          = 10497,
}

cgltf_sampler :: struct {
	name:             cstring,
	mag_filter:       cgltf_filter_type,
	min_filter:       cgltf_filter_type,
	wrap_s:           cgltf_wrap_mode,
	wrap_t:           cgltf_wrap_mode,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_texture :: struct {
	name:             cstring,
	image:            ^cgltf_image,
	sampler:          ^cgltf_sampler,
	has_basisu:       cgltf_bool,
	basisu_image:     ^cgltf_image,
	has_webp:         cgltf_bool,
	webp_image:       ^cgltf_image,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_texture_transform :: struct {
	offset:       [2]cgltf_float,
	rotation:     cgltf_float,
	scale:        [2]cgltf_float,
	has_texcoord: cgltf_bool,
	texcoord:     cgltf_int,
}

cgltf_texture_view :: struct {
	texture:       ^cgltf_texture,
	texcoord:      cgltf_int,
	scale:         cgltf_float, /* equivalent to strength for occlusion_texture */
	has_transform: cgltf_bool,
	transform:     cgltf_texture_transform,
}

cgltf_pbr_metallic_roughness :: struct {
	base_color_texture:         cgltf_texture_view,
	metallic_roughness_texture: cgltf_texture_view,
	base_color_factor:          [4]cgltf_float,
	metallic_factor:            cgltf_float,
	roughness_factor:           cgltf_float,
}

cgltf_pbr_specular_glossiness :: struct {
	diffuse_texture:             cgltf_texture_view,
	specular_glossiness_texture: cgltf_texture_view,
	diffuse_factor:              [4]cgltf_float,
	specular_factor:             [3]cgltf_float,
	glossiness_factor:           cgltf_float,
}

cgltf_clearcoat :: struct {
	clearcoat_texture:           cgltf_texture_view,
	clearcoat_roughness_texture: cgltf_texture_view,
	clearcoat_normal_texture:    cgltf_texture_view,
	clearcoat_factor:            cgltf_float,
	clearcoat_roughness_factor:  cgltf_float,
}

cgltf_transmission :: struct {
	transmission_texture: cgltf_texture_view,
	transmission_factor:  cgltf_float,
}

cgltf_ior :: struct {
	ior: cgltf_float,
}

cgltf_specular :: struct {
	specular_texture:       cgltf_texture_view,
	specular_color_texture: cgltf_texture_view,
	specular_color_factor:  [3]cgltf_float,
	specular_factor:        cgltf_float,
}

cgltf_volume :: struct {
	thickness_texture:    cgltf_texture_view,
	thickness_factor:     cgltf_float,
	attenuation_color:    [3]cgltf_float,
	attenuation_distance: cgltf_float,
}

cgltf_sheen :: struct {
	sheen_color_texture:     cgltf_texture_view,
	sheen_color_factor:      [3]cgltf_float,
	sheen_roughness_texture: cgltf_texture_view,
	sheen_roughness_factor:  cgltf_float,
}

cgltf_emissive_strength :: struct {
	emissive_strength: cgltf_float,
}

cgltf_iridescence :: struct {
	iridescence_factor:            cgltf_float,
	iridescence_texture:           cgltf_texture_view,
	iridescence_ior:               cgltf_float,
	iridescence_thickness_min:     cgltf_float,
	iridescence_thickness_max:     cgltf_float,
	iridescence_thickness_texture: cgltf_texture_view,
}

cgltf_diffuse_transmission :: struct {
	diffuse_transmission_texture:       cgltf_texture_view,
	diffuse_transmission_factor:        cgltf_float,
	diffuse_transmission_color_factor:  [3]cgltf_float,
	diffuse_transmission_color_texture: cgltf_texture_view,
}

cgltf_anisotropy :: struct {
	anisotropy_strength: cgltf_float,
	anisotropy_rotation: cgltf_float,
	anisotropy_texture:  cgltf_texture_view,
}

cgltf_dispersion :: struct {
	dispersion: cgltf_float,
}

cgltf_material :: struct {
	name:                        cstring,
	has_pbr_metallic_roughness:  cgltf_bool,
	has_pbr_specular_glossiness: cgltf_bool,
	has_clearcoat:               cgltf_bool,
	has_transmission:            cgltf_bool,
	has_volume:                  cgltf_bool,
	has_ior:                     cgltf_bool,
	has_specular:                cgltf_bool,
	has_sheen:                   cgltf_bool,
	has_emissive_strength:       cgltf_bool,
	has_iridescence:             cgltf_bool,
	has_diffuse_transmission:    cgltf_bool,
	has_anisotropy:              cgltf_bool,
	has_dispersion:              cgltf_bool,
	pbr_metallic_roughness:      cgltf_pbr_metallic_roughness,
	pbr_specular_glossiness:     cgltf_pbr_specular_glossiness,
	clearcoat:                   cgltf_clearcoat,
	ior:                         cgltf_ior,
	specular:                    cgltf_specular,
	sheen:                       cgltf_sheen,
	transmission:                cgltf_transmission,
	volume:                      cgltf_volume,
	emissive_strength:           cgltf_emissive_strength,
	iridescence:                 cgltf_iridescence,
	diffuse_transmission:        cgltf_diffuse_transmission,
	anisotropy:                  cgltf_anisotropy,
	dispersion:                  cgltf_dispersion,
	normal_texture:              cgltf_texture_view,
	occlusion_texture:           cgltf_texture_view,
	emissive_texture:            cgltf_texture_view,
	emissive_factor:             [3]cgltf_float,
	alpha_mode:                  cgltf_alpha_mode,
	alpha_cutoff:                cgltf_float,
	double_sided:                cgltf_bool,
	unlit:                       cgltf_bool,
	extras:                      cgltf_extras,
	extensions_count:            cgltf_size,
	extensions:                  ^cgltf_extension,
}

cgltf_material_mapping :: struct {
	variant:  cgltf_size,
	material: ^cgltf_material,
	extras:   cgltf_extras,
}

cgltf_morph_target :: struct {
	attributes:       ^cgltf_attribute,
	attributes_count: cgltf_size,
}

cgltf_draco_mesh_compression :: struct {
	buffer_view:      ^cgltf_buffer_view,
	attributes:       ^cgltf_attribute,
	attributes_count: cgltf_size,
}

cgltf_mesh_gpu_instancing :: struct {
	attributes:       ^cgltf_attribute,
	attributes_count: cgltf_size,
}

cgltf_primitive :: struct {
	type:                       cgltf_primitive_type,
	indices:                    ^cgltf_accessor,
	material:                   ^cgltf_material,
	attributes:                 ^cgltf_attribute,
	attributes_count:           cgltf_size,
	targets:                    ^cgltf_morph_target,
	targets_count:              cgltf_size,
	extras:                     cgltf_extras,
	has_draco_mesh_compression: cgltf_bool,
	draco_mesh_compression:     cgltf_draco_mesh_compression,
	mappings:                   ^cgltf_material_mapping,
	mappings_count:             cgltf_size,
	extensions_count:           cgltf_size,
	extensions:                 ^cgltf_extension,
}

cgltf_mesh :: struct {
	name:               cstring,
	primitives:         ^cgltf_primitive,
	primitives_count:   cgltf_size,
	weights:            ^cgltf_float,
	weights_count:      cgltf_size,
	target_names:       ^cstring,
	target_names_count: cgltf_size,
	extras:             cgltf_extras,
	extensions_count:   cgltf_size,
	extensions:         ^cgltf_extension,
}

cgltf_skin :: struct {
	name:                  cstring,
	joints:                ^^cgltf_node,
	joints_count:          cgltf_size,
	skeleton:              ^cgltf_node,
	inverse_bind_matrices: ^cgltf_accessor,
	extras:                cgltf_extras,
	extensions_count:      cgltf_size,
	extensions:            ^cgltf_extension,
}

cgltf_camera_perspective :: struct {
	has_aspect_ratio: cgltf_bool,
	aspect_ratio:     cgltf_float,
	yfov:             cgltf_float,
	has_zfar:         cgltf_bool,
	zfar:             cgltf_float,
	znear:            cgltf_float,
	extras:           cgltf_extras,
}

cgltf_camera_orthographic :: struct {
	xmag:   cgltf_float,
	ymag:   cgltf_float,
	zfar:   cgltf_float,
	znear:  cgltf_float,
	extras: cgltf_extras,
}

cgltf_camera :: struct {
	name: cstring,
	type: cgltf_camera_type,

	data: struct #raw_union {
		perspective:  cgltf_camera_perspective,
		orthographic: cgltf_camera_orthographic,
	},

	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_light :: struct {
	name:                  cstring,
	color:                 [3]cgltf_float,
	intensity:             cgltf_float,
	type:                  cgltf_light_type,
	range:                 cgltf_float,
	spot_inner_cone_angle: cgltf_float,
	spot_outer_cone_angle: cgltf_float,
	extras:                cgltf_extras,
}

cgltf_node :: struct {
	name:                    cstring,
	parent:                  ^cgltf_node,
	children:                ^^cgltf_node,
	children_count:          cgltf_size,
	skin:                    ^cgltf_skin,
	mesh:                    ^cgltf_mesh,
	camera:                  ^cgltf_camera,
	light:                   ^cgltf_light,
	weights:                 ^cgltf_float,
	weights_count:           cgltf_size,
	has_translation:         cgltf_bool,
	has_rotation:            cgltf_bool,
	has_scale:               cgltf_bool,
	has_matrix:              cgltf_bool,
	translation:             [3]cgltf_float,
	rotation:                [4]cgltf_float,
	scale:                   [3]cgltf_float,
	_matrix:                 [16]cgltf_float,
	extras:                  cgltf_extras,
	has_mesh_gpu_instancing: cgltf_bool,
	mesh_gpu_instancing:     cgltf_mesh_gpu_instancing,
	extensions_count:        cgltf_size,
	extensions:              ^cgltf_extension,
}

cgltf_scene :: struct {
	name:             cstring,
	nodes:            ^^cgltf_node,
	nodes_count:      cgltf_size,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_animation_sampler :: struct {
	input:            ^cgltf_accessor,
	output:           ^cgltf_accessor,
	interpolation:    cgltf_interpolation_type,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_animation_channel :: struct {
	sampler:          ^cgltf_animation_sampler,
	target_node:      ^cgltf_node,
	target_path:      cgltf_animation_path_type,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_animation :: struct {
	name:             cstring,
	samplers:         ^cgltf_animation_sampler,
	samplers_count:   cgltf_size,
	channels:         ^cgltf_animation_channel,
	channels_count:   cgltf_size,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_material_variant :: struct {
	name:   cstring,
	extras: cgltf_extras,
}

cgltf_asset :: struct {
	copyright:        cstring,
	generator:        cstring,
	version:          cstring,
	min_version:      cstring,
	extras:           cgltf_extras,
	extensions_count: cgltf_size,
	extensions:       ^cgltf_extension,
}

cgltf_data :: struct {
	file_type:                 cgltf_file_type,
	file_data:                 rawptr,
	file_size:                 cgltf_size,
	asset:                     cgltf_asset,
	meshes:                    ^cgltf_mesh,
	meshes_count:              cgltf_size,
	materials:                 ^cgltf_material,
	materials_count:           cgltf_size,
	accessors:                 ^cgltf_accessor,
	accessors_count:           cgltf_size,
	buffer_views:              ^cgltf_buffer_view,
	buffer_views_count:        cgltf_size,
	buffers:                   ^cgltf_buffer,
	buffers_count:             cgltf_size,
	images:                    ^cgltf_image,
	images_count:              cgltf_size,
	textures:                  ^cgltf_texture,
	textures_count:            cgltf_size,
	samplers:                  ^cgltf_sampler,
	samplers_count:            cgltf_size,
	skins:                     ^cgltf_skin,
	skins_count:               cgltf_size,
	cameras:                   ^cgltf_camera,
	cameras_count:             cgltf_size,
	lights:                    ^cgltf_light,
	lights_count:              cgltf_size,
	nodes:                     ^cgltf_node,
	nodes_count:               cgltf_size,
	scenes:                    ^cgltf_scene,
	scenes_count:              cgltf_size,
	scene:                     ^cgltf_scene,
	animations:                ^cgltf_animation,
	animations_count:          cgltf_size,
	variants:                  ^cgltf_material_variant,
	variants_count:            cgltf_size,
	extras:                    cgltf_extras,
	data_extensions_count:     cgltf_size,
	data_extensions:           ^cgltf_extension,
	extensions_used:           ^cstring,
	extensions_used_count:     cgltf_size,
	extensions_required:       ^cstring,
	extensions_required_count: cgltf_size,
	json:                      cstring,
	json_size:                 cgltf_size,
	bin:                       rawptr,
	bin_size:                  cgltf_size,
	memory:                    cgltf_memory_options,
	file:                      cgltf_file_options,
}

@(default_calling_convention="c", link_prefix="cgltf_")
foreign lib {
	parse                   :: proc(options: ^cgltf_options, data: rawptr, size: cgltf_size, out_data: ^^cgltf_data) -> cgltf_result ---
	parse_file              :: proc(options: ^cgltf_options, path: cstring, out_data: ^^cgltf_data) -> cgltf_result ---
	load_buffers            :: proc(options: ^cgltf_options, data: ^cgltf_data, gltf_path: cstring) -> cgltf_result ---
	load_buffer_base64      :: proc(options: ^cgltf_options, size: cgltf_size, base64: cstring, out_data: ^rawptr) -> cgltf_result ---
	decode_string           :: proc(_string: cstring) -> cgltf_size ---
	decode_uri              :: proc(uri: cstring) -> cgltf_size ---
	validate                :: proc(data: ^cgltf_data) -> cgltf_result ---
	free                    :: proc(data: ^cgltf_data) ---
	node_transform_local    :: proc(node: ^cgltf_node, out_matrix: ^cgltf_float) ---
	node_transform_world    :: proc(node: ^cgltf_node, out_matrix: ^cgltf_float) ---
	buffer_view_data        :: proc(view: ^cgltf_buffer_view) -> ^u8 ---
	find_accessor           :: proc(prim: ^cgltf_primitive, type: cgltf_attribute_type, index: cgltf_int) -> ^cgltf_accessor ---
	accessor_read_float     :: proc(accessor: ^cgltf_accessor, index: cgltf_size, out: ^cgltf_float, element_size: cgltf_size) -> cgltf_bool ---
	accessor_read_uint      :: proc(accessor: ^cgltf_accessor, index: cgltf_size, out: ^cgltf_uint, element_size: cgltf_size) -> cgltf_bool ---
	accessor_read_index     :: proc(accessor: ^cgltf_accessor, index: cgltf_size) -> cgltf_size ---
	num_components          :: proc(type: cgltf_type) -> cgltf_size ---
	component_size          :: proc(component_type: cgltf_component_type) -> cgltf_size ---
	calc_size               :: proc(type: cgltf_type, component_type: cgltf_component_type) -> cgltf_size ---
	accessor_unpack_floats  :: proc(accessor: ^cgltf_accessor, out: ^cgltf_float, float_count: cgltf_size) -> cgltf_size ---
	accessor_unpack_indices :: proc(accessor: ^cgltf_accessor, out: rawptr, out_component_size: cgltf_size, index_count: cgltf_size) -> cgltf_size ---

	/* this function is deprecated and will be removed in the future; use cgltf_extras::data instead */
	copy_extras_json        :: proc(data: ^cgltf_data, extras: ^cgltf_extras, dest: cstring, dest_size: ^cgltf_size) -> cgltf_result ---
	mesh_index              :: proc(data: ^cgltf_data, object: ^cgltf_mesh) -> cgltf_size ---
	material_index          :: proc(data: ^cgltf_data, object: ^cgltf_material) -> cgltf_size ---
	accessor_index          :: proc(data: ^cgltf_data, object: ^cgltf_accessor) -> cgltf_size ---
	buffer_view_index       :: proc(data: ^cgltf_data, object: ^cgltf_buffer_view) -> cgltf_size ---
	buffer_index            :: proc(data: ^cgltf_data, object: ^cgltf_buffer) -> cgltf_size ---
	image_index             :: proc(data: ^cgltf_data, object: ^cgltf_image) -> cgltf_size ---
	texture_index           :: proc(data: ^cgltf_data, object: ^cgltf_texture) -> cgltf_size ---
	sampler_index           :: proc(data: ^cgltf_data, object: ^cgltf_sampler) -> cgltf_size ---
	skin_index              :: proc(data: ^cgltf_data, object: ^cgltf_skin) -> cgltf_size ---
	camera_index            :: proc(data: ^cgltf_data, object: ^cgltf_camera) -> cgltf_size ---
	light_index             :: proc(data: ^cgltf_data, object: ^cgltf_light) -> cgltf_size ---
	node_index              :: proc(data: ^cgltf_data, object: ^cgltf_node) -> cgltf_size ---
	scene_index             :: proc(data: ^cgltf_data, object: ^cgltf_scene) -> cgltf_size ---
	animation_index         :: proc(data: ^cgltf_data, object: ^cgltf_animation) -> cgltf_size ---
	animation_sampler_index :: proc(animation: ^cgltf_animation, object: ^cgltf_animation_sampler) -> cgltf_size ---
	animation_channel_index :: proc(animation: ^cgltf_animation, object: ^cgltf_animation_channel) -> cgltf_size ---
}

