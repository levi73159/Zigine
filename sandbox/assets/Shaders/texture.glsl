#global_version 330 core
#type vertex

layout (location = 0) in vec3 a_Position;
layout (location = 1) in vec2 a_TexCoord;

out vec2 v_TexCoord;

uniform mat4 u_VP;
uniform mat4 u_Transform;

void main() {
    // flip y for TexCoord
    v_TexCoord = vec2(a_TexCoord.x, 1.0 - a_TexCoord.y);
    gl_Position = u_VP * u_Transform * vec4(a_Position, 1.0);
}

#type fragment

layout(location = 0) out vec4 FragColor;

in vec2 v_TexCoord;

uniform sampler2D u_Texture;

void main() {
    FragColor = texture(u_Texture, v_TexCoord) ;
}
