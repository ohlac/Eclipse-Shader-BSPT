#version 430 compatibility

#include "/lib/settings.glsl"

layout(triangles) in;

#ifdef LPV_SHADOWS
    #if LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE == 1
        layout(triangle_strip, max_vertices = 18) out;
    #elif LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE == 2
        layout(triangle_strip, max_vertices = 33) out;
    #elif LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE == 3
        layout(triangle_strip, max_vertices = 48) out;
    #elif LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE == 4
        layout(triangle_strip, max_vertices = 63) out;
    #elif LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE == 5
        layout(triangle_strip, max_vertices = 78) out;
    #elif LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE == 6
        layout(triangle_strip, max_vertices = 93) out;
    #elif LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE == 7
        layout(triangle_strip, max_vertices = 108) out;
    #elif LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE == 8
        layout(triangle_strip, max_vertices = 123) out;
    #else
        layout(triangle_strip, max_vertices = 138) out;
    #endif
#else
    layout(triangle_strip, max_vertices = 3) out;
#endif

#ifdef LPV_SHADOWS
in DATA {
    vec2 texcoord;
    vec3 color;
} IN[];

out DATA {
    vec2 texcoord;
};
#else
in DATA {
    vec2 texcoord;
    vec3 color;
    vec3 playerpos;
} IN[];

out DATA {
    vec2 texcoord;
    vec3 color;
    vec3 playerpos;
};
#endif

#ifdef LPV_SHADOWS
    in vec3 worldPos[];
    flat in vec3 worldNormal[];
    flat out int render;

    #include "/lib/cube/emit.glsl"
    #include "/lib/cube/lightData.glsl"

    uniform usampler1D texCloseLights;
    uniform vec3 cameraPosition;
    uniform vec3 previousCameraPosition;
    #ifdef LPV_HAND_SHADOWS
        uniform vec3 relativeEyePosition;
        uniform vec3 playerLookVector;
    #endif
#endif

void main() {
    #ifdef LPV_SHADOWS
        for (int i = 0; i < LPV_SHADOWS_LIGHT_COUNT_EFFECTIVE; i++) {
            uint data = texelFetch(texCloseLights, i, 0).r;
            float dist;
            ivec3 pos;
            uint id;
            if (getLightData(data, dist, pos, id)) {
                vec3 lightPos = -fract(previousCameraPosition) + (previousCameraPosition - cameraPosition) + vec3(pos) - 14.5;
                #ifdef LPV_HAND_SHADOWS
                    if (dist < 0.0001) {
                        vec2 viewDir = normalize(playerLookVector.xz) * 0.25;
                        lightPos = -relativeEyePosition + vec3(viewDir.x, 0.0, viewDir.y);
                    }
                #endif

                vec3 dists = vec3(length(worldPos[0] - lightPos), length(worldPos[1] - lightPos), length(worldPos[2] - lightPos));
                if (all(lessThan(dists, vec3(14.0))) &&
                    (max(max(dists.x, dists.y), dists.z) > 1.45 || dot(worldNormal[0], worldPos[0] - lightPos) < 0.0)) {
                    for (int f = 0; f < 6; f++) {
                        render = i + f * 16;
                        emitCubemap(directionMatices[f], cubeFaceOffsets[f] * 2 + renderOffsets[i] * 2, lightPos);
                    }
                }
            } else {
                break;
            }
        }
        render = -1;
    #endif

    for (int i = 0; i < 3; i++) {
        gl_Position = gl_in[i].gl_Position;
        #ifdef LPV_SHADOWS
            gl_Position.xy = gl_Position.xy * 0.8 - 0.2 * gl_Position.w;
        #endif
        texcoord = IN[i].texcoord;
        #ifndef LPV_SHADOWS
        color = IN[i].color;
        playerpos = IN[i].playerpos;
        #endif
        EmitVertex();
    }
    EndPrimitive();
}
