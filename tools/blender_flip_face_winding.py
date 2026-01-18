
bl_info = {
    "name": "Reverse Selected Face Winding",
    "author": "ChatGPT",
    "version": (1, 0),
    "blender": (3, 0, 0),
    "location": "Edit Mode > Face > Reverse Face Winding",
    "description": "Reverses vertex winding order of selected faces",
    "category": "Mesh",
}

import bpy
import bmesh


class MESH_OT_reverse_face_winding(bpy.types.Operator):
    bl_idname = "mesh.reverse_face_winding"
    bl_label = "Reverse Face Winding"
    bl_options = {'REGISTER', 'UNDO'}

    @classmethod
    def poll(cls, context):
        obj = context.active_object
        return obj and obj.type == 'MESH' and context.mode == 'EDIT_MESH'

    def execute(self, context):
        obj = context.active_object
        mesh = obj.data

        bm = bmesh.from_edit_mesh(mesh)
        bm.faces.ensure_lookup_table()

        count = 0
        for face in bm.faces:
            if face.select:
                face.normal_flip()
                count += 1

        bmesh.update_edit_mesh(mesh, loop_triangles=False, destructive=False)

        self.report({'INFO'}, f"Reversed winding on {count} faces")
        return {'FINISHED'}


def menu_func(self, context):
    self.layout.operator(MESH_OT_reverse_face_winding.bl_idname)


def register():
    bpy.utils.register_class(MESH_OT_reverse_face_winding)
    bpy.types.VIEW3D_MT_edit_mesh_faces.append(menu_func)


def unregister():
    bpy.types.VIEW3D_MT_edit_mesh_faces.remove(menu_func)
    bpy.utils.unregister_class(MESH_OT_reverse_face_winding)


if __name__ == "__main__":
    register()