//
//  ParticleShader.metal
//  tts
//
//  Created by NY on 2025/5/19.
//

#include <metal_stdlib>
using namespace metal;

struct Particle {
    float2 position;
    float2 velocity;
    float alpha;
    float scale;
};

kernel void updateParticles(device Particle *particles [[buffer(0)]],
                           uint gid [[thread_position_in_grid]]) {
    Particle p = particles[gid];
    p.position += p.velocity * 0.016; // Assuming 60 FPS
    p.alpha -= 0.016 / 3.0; // Fade out over 3 seconds
    p.velocity.y += 50.0 * 0.016; // Upward acceleration
    if (p.alpha < 0.0) p.alpha = 0.0;
    particles[gid] = p;
}

vertex float4 vertexShader(device Particle *particles [[buffer(0)]],
                          uint vid [[vertex_id]]) {
    Particle p = particles[vid];
    float4 pos = float4(p.position.x, p.position.y, 0.0, 1.0);
    return pos;
}

fragment float4 fragmentShader(float4 in [[stage_in]]) {
    return float4(1.0, 1.0, 1.0, in.w); // White particles with alpha
}
