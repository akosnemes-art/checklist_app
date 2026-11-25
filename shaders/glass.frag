#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform vec3 uBase;
uniform vec3 uBlue;
uniform vec3 uLilac;
uniform float uLens;

out vec4 fragColor;

vec3 wallpaper(vec2 uv) {
    float cool = exp(-3.4 * dot(uv - vec2(0.12, 0.04), uv - vec2(0.12, 0.04)));
    float warm = exp(-4.5 * dot(uv - vec2(0.93, 0.30), uv - vec2(0.93, 0.30)));
    float streak = 1.0 - smoothstep(0.0, 0.19, abs(uv.y - 0.60 + 0.34 * uv.x));
    return mix(mix(uBase, uBlue, cool * 0.68), uLilac,
               clamp(warm * 0.67 + streak * 0.17, 0.0, 1.0));
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    vec2 edge = min(uv, 1.0 - uv);
    float bevel = 1.0 - smoothstep(0.0, 0.17, min(edge.x, edge.y));
    // Bend the procedural wallpaper at the bevel, with a small ribbon across the face.
    vec2 bent = uv + (uv - 0.5) * bevel * uLens * 0.16;
    bent.y += sin(uv.x * 3.14 + uv.y * 6.28) * uLens * 0.033;
    vec3 colour = wallpaper(bent);
    float litEdge = (1.0 - smoothstep(0.0, 0.050, edge.y + 0.35 * uv.y))
                    * uLens;
    colour = mix(colour, vec3(1.0), uLens * 0.17 + litEdge * 0.26);
    fragColor = vec4(colour, 1.0);
}
