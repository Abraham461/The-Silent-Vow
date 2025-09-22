shader_type canvas_item;

uniform vec2 u_center_uv = vec2(0.5, 0.5);
uniform float u_radius_uv = 0.0;
uniform float u_feather_uv = 0.05;
uniform float u_darkness = 0.0;
uniform int u_spot_enabled = 0;

void fragment() {
    vec2 uv = SCREEN_UV; // normalized 0..1
    float d = distance(uv, u_center_uv);
    float mask = smoothstep(u_radius_uv - u_feather_uv, u_radius_uv + u_feather_uv, d);

    if (u_spot_enabled == 0) {
        mask = 0.0;
    }

    float alpha = u_darkness * (1.0 - mask);
    COLOR = vec4(vec3(0.0), alpha);
}
