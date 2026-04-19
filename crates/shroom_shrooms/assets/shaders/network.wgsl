#import bevy_sprite::mesh2d_vertex_output::VertexOutput

struct NetworkUniforms {
    core_color: vec4<f32>,
    body_color: vec4<f32>,
    biomass: f32,
    time: f32,
    _padding: vec2<f32>,
};

@group(2) @binding(0) var<uniform> material: NetworkUniforms;

fn hash21(p: vec2<f32>) -> f32 {
    var p3 = fract(vec3<f32>(p.x, p.y, p.x) * 0.1031);
    p3 = p3 + dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

fn noise1d(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash21(i), hash21(i + vec2<f32>(1.0, 0.0)), u.x),
        mix(hash21(i + vec2<f32>(0.0, 1.0)), hash21(i + vec2<f32>(1.0, 1.0)), u.x),
        u.y
    );
}

@fragment
fn fragment(mesh: VertexOutput) -> @location(0) vec4<f32> {
    let uv = mesh.uv;
    let u = uv.x;
    let v = uv.y;
    let abs_u = abs(u);

    let glow_intensity = clamp(material.biomass * 0.2, 0.1, 1.0);

    // Layer 1: Core — bright tight spine
    let core_width = 0.15;
    let core = smoothstep(core_width, core_width * 0.3, abs_u);
    let core_color = material.core_color.rgb * (1.2 + glow_intensity * 0.8);

    // Layer 2: Fibrous body with value noise texture
    let body_width = 0.55;
    let body = smoothstep(body_width, body_width * 0.5, abs_u);
    let fiber = noise1d(vec2<f32>(u * 3.0, v * 20.0 + material.time * 0.5));
    let body_color = material.body_color.rgb * (0.5 + fiber * 0.3);

    // Layer 3: Soft glow falloff to edge
    let glow_edge = 1.0;
    let glow = smoothstep(glow_edge, 0.3, abs_u) * glow_intensity;
    let glow_color = material.core_color.rgb * 0.3;

    // Composite layers back-to-front
    var color = glow_color * glow;
    let alpha = glow * 0.3;
    color = mix(color, body_color, body * 0.8);
    color = mix(color, core_color, core);

    // Low-biomass flicker — network looks starved/unstable
    if material.biomass < 1.5 {
        let flicker = sin(material.time * 8.0 + v * 12.0) * 0.5 + 0.5;
        let flicker_strength = (1.5 - material.biomass) / 1.5 * 0.4;
        color = color * (1.0 - flicker_strength * flicker);
    }

    let final_alpha = max(max(core * 0.95, body * 0.7), alpha);
    return vec4<f32>(color, final_alpha);
}
