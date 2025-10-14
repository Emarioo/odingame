package assimp

ASSIMP_SHARED :: #config(ASSIMP_SHARED, false)

when ODIN_OS == .Windows {
	foreign import assimp {
		"windows/assimp-vc143-mtd.dll" when ASSIMP_SHARED else "windows/assimp-vc143-mtd.lib",
	}
} else when ODIN_OS == .Linux  {
	foreign import lib {
		"linux/libassimp.so" when ASSIMP_SHARED else "linux/libassimp.a",
	}
} else {
	
}

aiPropertyTypeInfo :: enum {
    aiPTI_Float = 0x1,
    aiPTI_Double = 0x2,
    aiPTI_String = 0x3,
    aiPTI_Integer = 0x4,
    aiPTI_Buffer = 0x5,
}

aiMaterialProperty :: struct {
	 mKey : aiString,
	 mSemantic : u32,
	 mIndex : u32,
	 mDataLength : u32,
	 mType : aiPropertyTypeInfo,
	 mData : ^u8,
}

aiMaterial :: struct {
    mProperties : ^^aiMaterialProperty,
    mNumProperties: u32,
    mNumAllocated: u32,
}

AI_MAX_NUMBER_OF_COLOR_SETS :: 0x8
AI_MAX_NUMBER_OF_TEXTURECOORDS :: 0x8

aiBone :: struct {
    mName : aiString,
    mNumWeights : u32,
    mArmature : ^aiNode,
    mNode : ^aiNode,
    mWeights : [^]aiVertexWeight,
    mOffsetMatrix : aiMatrix4x4,
}
aiAnimMesh :: struct {
    mName : aiString,
    mVertices : [^]aiVector3D,
    mNormals : [^]aiVector3D,
    mTangents : [^]aiVector3D,
    mBitangents : [^]aiVector3D,
    mColors : [AI_MAX_NUMBER_OF_COLOR_SETS][^]aiColor4D,
    mTextureCoords : [AI_MAX_NUMBER_OF_TEXTURECOORDS][^]aiVector3D,
    mNumVertices : u32,
    mWeight : f32,
}
aiFace :: struct {
    mNumIndices : u32,
    mIndices : [^]u32,
}
aiVertexWeight :: struct {
	mVertexId : u32,
    mWeight : f32,
}

aiVector3D :: struct { xyz : [3]f32 }
aiColor4D :: struct { xyzw : [4]f32 }


aiMorphingMethod :: enum {
    aiMorphingMethod_UNKNOWN = 0x0,
    aiMorphingMethod_VERTEX_BLEND = 0x1,
    aiMorphingMethod_MORPH_NORMALIZED = 0x2,
    aiMorphingMethod_MORPH_RELATIVE = 0x3,
}

aiAABB :: struct {
	mMin : aiVector3D,
	mMax : aiVector3D,
}
aiMesh :: struct {
	 mPrimitiveTypes : u32,
	 mNumVertices : u32,
	 mNumFaces : u32,
	 mVertices : [^]aiVector3D,
	 mNormals : [^]aiVector3D,
	 mTangents : [^]aiVector3D,
	 mBitangents : [^]aiVector3D,
	 mColors : [AI_MAX_NUMBER_OF_COLOR_SETS][^]aiColor4D,
	 mTextureCoords : [AI_MAX_NUMBER_OF_TEXTURECOORDS][^]aiVector3D,
	 mNumUVComponents : [AI_MAX_NUMBER_OF_TEXTURECOORDS]u32,
	 mFaces : [^]aiFace,
	 mNumBones : u32,
	 mBones : [^]^aiBone,
	 mMaterialIndex : u32,
	 mName : aiString,
	 mNumAnimMeshes : u32,
	 mAnimMeshes : [^]^aiAnimMesh,
	 mMethod : aiMorphingMethod,
	 mAABB : aiAABB,
	 mTextureCoordsNames : [^]^aiString,
}

aiAnimation :: struct {}
aiTexture :: struct {}
aiLight :: struct {}
aiCamera :: struct {}
aiSkeleton :: struct {}

aiScene :: struct {
    mFlags : u32,
    mRootNode : ^aiNode,
    mNumMeshes : u32,
    mMeshes : [^]^aiMesh,
	mNumMaterials : u32,
	mMaterials : [^]^aiMaterial,
    mNumAnimations : u32,
    mAnimations : [^]^aiAnimation,
    mNumTextures : u32,
    mTextures : [^]^aiTexture,
    mNumLights : u32,
    mLights : [^]^aiLight,
    mNumCameras:  u32,
    mCameras : [^]^aiCamera,
    mMetaData : ^aiMetadata,
    mName : aiString,
    mNumSkeletons : u32,
    mSkeletons : [^]^aiSkeleton,
}


AI_MAXLEN :: 1024

aiNode :: struct {
    mName : aiString,
    mTransformation : aiMatrix4x4,
    mParent : ^aiNode,
    mNumChildren : u32,
    mChildren : [^]^aiNode,
    mNumMeshes : u32,
    mMeshes : [^]u32,
    mMetaData : ^aiMetadata,
}


aiMetadata :: struct {
    mNumProperties : u32,
    mKeys : [^]aiString,
    mValues : [^]aiMetadataEntry,
}

aiMetadataType :: enum {
    AI_BOOL = 0,
    AI_INT32 = 1,
    AI_UINT64 = 2,
    AI_FLOAT = 3,
    AI_DOUBLE = 4,
    AI_AISTRING = 5,
    AI_AIVECTOR3D = 6,
    AI_AIMETADATA = 7,
    AI_INT64 = 8,
    AI_UINT32 = 9,
    AI_META_MAX = 10,
}

aiMetadataEntry :: struct {
    mType : aiMetadataType,
    mData : rawptr,
}
ai_real :: f32

aiMatrix4x4 :: struct {
     a1, a2, a3, a4 : ai_real,
     b1, b2, b3, b4 : ai_real,
     c1, c2, c3, c4 : ai_real,
     d1, d2, d3, d4 : ai_real,
};

aiString :: struct {
	length: u32,
	data: [AI_MAXLEN]u8
};
 

aiPostProcessSteps :: enum {
    aiProcess_CalcTangentSpace = 0x1,
    aiProcess_JoinIdenticalVertices = 0x2,
    aiProcess_MakeLeftHanded = 0x4,
    aiProcess_Triangulate = 0x8,
    aiProcess_RemoveComponent = 0x10,
    aiProcess_GenNormals = 0x20,
    aiProcess_GenSmoothNormals = 0x40,
    aiProcess_SplitLargeMeshes = 0x80,
    aiProcess_PreTransformVertices = 0x100,
    aiProcess_LimitBoneWeights = 0x200,
    aiProcess_ValidateDataStructure = 0x400,
    aiProcess_ImproveCacheLocality = 0x800,
    aiProcess_RemoveRedundantMaterials = 0x1000,
    aiProcess_FixInfacingNormals = 0x2000,
    aiProcess_PopulateArmatureData = 0x4000,
    aiProcess_SortByPType = 0x8000,
    aiProcess_FindDegenerates = 0x10000,
    aiProcess_FindInvalidData = 0x20000,
    aiProcess_GenUVCoords = 0x40000,
    aiProcess_TransformUVCoords = 0x80000,
    aiProcess_FindInstances = 0x100000,
    aiProcess_OptimizeMeshes  = 0x200000,
    aiProcess_OptimizeGraph  = 0x400000,
    aiProcess_FlipUVs = 0x800000,
    aiProcess_FlipWindingOrder  = 0x1000000,
    aiProcess_SplitByBoneCount  = 0x2000000,
    aiProcess_Debone  = 0x4000000,
    aiProcess_GlobalScale = 0x8000000,
    aiProcess_EmbedTextures  = 0x10000000,
    aiProcess_ForceGenNormals = 0x20000000,
    aiProcess_DropNormals = 0x40000000,
    aiProcess_GenBoundingBoxes = 0x80000000
};

foreign assimp {
	aiImportFile :: proc "c" (pFile: cstring, pFlags: u32) -> ^aiScene ---
	aiGetErrorString :: proc "c" () -> cstring ---
	aiReleaseImport :: proc "c" (pScene: ^aiScene) ---
}