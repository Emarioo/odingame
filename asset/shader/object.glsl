#vertex
#version 330 core

layout (location = 0) in vec3 vPos;


out vec3 fPos;
// flat out vec3 fNormal;
// out vec2 fUV;
// flat out int fMaterial;

// out vec4 fPosLightSpace;

uniform mat4 uTransform;
uniform mat4 uProjection;
// uniform mat4 uLightSpaceMatrix;

void main()
{
	mat4 transform = uTransform;
	// if(uTransform[0][0]==0){ // do we use instancing?
	// 	transform = mat4(iPos1,iPos2,iPos3,iPos4);
	// }
	fPos = vec3(transform * vec4(vPos,1));

	// fNormal = fPos-vec3(transform * vec4(vPos-vNormal, 1));

	// fUV = vTexture.xy;
	// fMaterial = int(vTexture.z);
	// fPosLightSpace = uLightSpaceMatrix * vec4(fPos, 1);

	//fNormal = mat3(transpose(inverse(transform)))*vNormal; // Do this on the cpu and pass into the shader via uniform, per vertex. if needed...
	
	gl_Position = uProjection * vec4(fPos,1);
};

#fragment
#version 330 core
out vec4 FragColor;

// uniform PointLight uPointLights[N_POINTLIGHTS];
// uniform SpotLight uSpotLights[N_SPOTLIGHTS];
// uniform DirLight uDirLight;
// uniform ivec3 uLightCount;
uniform vec3 uCameraPos;
// uniform Material uMaterials[N_MATERIALS];
// uniform sampler2D shadow_map;

in vec3 fPos;
// flat in vec3 fNormal;
// in vec2 fUV;
// flat in int fMaterial;
// in vec4 fPosLightSpace;

void main()
{
	//vec3 normal = texture(uMaterials.normal_map, fUV).rgb*fNormal;
	//normal = normalize((normal * 2 - 1));
	// vec3 normal = normalize(fNormal);

	// vec3 viewDir = normalize(uCameraPos - fPos);
	
	// float shadow = ShadowCalculation(fPosLightSpace);

	// vec3 result = vec3(0);
	// if(uLightCount.x==1)
	// 	result += CalcDirLight(uDirLight, normal, viewDir, 0);
	// for (int i = 0; i < uLightCount.y;i++) {
	// 	result += CalcPointLight(uPointLights[i], normal, fPos, viewDir, 0);
	// }
	// for (int i = 0; i < uLightCount.z; i++) {
	// 	result += CalcSpotLight(uSpotLights[i], normal, fPos, viewDir, 0);
	// }

	//texture(uMaterials[fMaterial].diffuse_map, fUV).rgb * 
	
	// result *= uMaterials[fMaterial].diffuse_color;
	// if(uMaterials[fMaterial].useMap==1){
	// 	result *= texture(uMaterials[fMaterial].diffuse_map, fUV).rgb;
	// }
	// FragColor = vec4(result, 1);

    // FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
    FragColor = vec4(1.0f, 1.0f, 1.0f, 1.0f);
}