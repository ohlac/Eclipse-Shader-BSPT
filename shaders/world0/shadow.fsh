#version 430 compatibility

#include "/lib/settings.glsl"

#ifdef LPV_SHADOWS
in DATA {
	vec2 texcoord;
};
#else
in DATA {
	vec2 texcoord;
	vec3 color;	
	vec3 playerpos;
};
#endif

uniform sampler2D gtexture;
uniform sampler2D noisetex;

#ifdef LPV_SHADOWS
#include "/lib/cube/cubeData.glsl"
flat in int render;
#endif

#if defined DISTANT_HORIZONS && DH_CHUNK_FADING > 1
	uniform float far;
#endif

#ifndef LPV_SHADOWS
in float LIGHTNING;
#else
const float LIGHTNING = 0.0;
#endif
uniform float frameTimeCounter;

float blueNoise(){
  return fract(texelFetch(noisetex, ivec2(gl_FragCoord.xy)%512, 0).a + 1.0/1.6180339887 );
}

uniform int renderStage;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////


void main() {
	if (LIGHTNING > 0.0) discard;

	#ifdef LPV_SHADOWS
		if (render >= 0 && (
			any(lessThan(gl_FragCoord.xy, minBounds[render >> 4] + renderBounds[render & 15])) ||
			any(greaterThan(gl_FragCoord.xy, maxBounds[render >> 4] + renderBounds[render & 15])))) {
			discard;
			return;
		}
	#endif

	#if defined DISTANT_HORIZONS && DH_CHUNK_FADING > 1 && !defined LPV_SHADOWS
		float viewDist = length(playerpos);
		float minDist = min(shadowDistance, far);

		float ditherFade = smoothstep(0.93 * minDist, minDist, viewDist);

		if (step(ditherFade, blueNoise()) == 0.0) discard;
	#endif
	
	#ifdef LPV_SHADOWS
	vec4 shadowColor = texture(gtexture, texcoord.xy);
#else
	vec4 shadowColor = vec4(texture(gtexture,texcoord.xy).rgb * color,  textureLod(gtexture, texcoord.xy, 0).a);
#endif

	// #ifdef TRANSLUCENT_COLORED_SHADOWS
	// 	if(shadowColor.a > 0.9999) shadowColor.rgb = vec3(0.0);
	// #endif

	gl_FragData[0] = shadowColor;

	// gl_FragData[0] = vec4(texture(tex,texcoord.xy).rgb * color.rgb,  textureLod(tex, texcoord.xy, 0).a);

  	#ifdef Stochastic_Transparent_Shadows
		if(gl_FragData[0].a < blueNoise() && (renderStage == MC_RENDER_STAGE_TERRAIN_TRANSLUCENT || renderStage == MC_RENDER_STAGE_ENTITIES || renderStage == MC_RENDER_STAGE_BLOCK_ENTITIES || renderStage == MC_RENDER_STAGE_NONE)) { discard; return;}
  	#endif
}
