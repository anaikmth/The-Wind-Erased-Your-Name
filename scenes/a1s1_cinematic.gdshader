shader_type canvas_item;

void fragment() {
    vec2 uv = UV;
    
    // Respiration lente et profonde
    float breathe = sin(TIME * 0.25) * 0.018;
    uv += vec2(breathe, breathe * 0.7);
    
    // Distorsion qui rampe lentement
    uv.x += sin(uv.y * 2.0 + TIME * 0.15) * 0.018;
    uv.y += sin(uv.x * 1.5 + TIME * 0.12) * 0.014;
    
    // Légère rotation autour du centre
    vec2 center = uv - 0.5;
    float rot = sin(TIME * 0.08) * 0.012;
    center = vec2(
        center.x * cos(rot) - center.y * sin(rot),
        center.x * sin(rot) + center.y * cos(rot)
    );
    uv = center + 0.5;
    
    vec4 col = texture(TEXTURE, uv);
    
    // Aberration chromatique très subtile
    float aber = 0.003;
    col.r = texture(TEXTURE, uv + vec2(aber, 0.0)).r;
    col.b = texture(TEXTURE, uv - vec2(aber, 0.0)).b;
    
    COLOR = col;
}