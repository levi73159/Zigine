#version 330 core

layout (location = 0) in vec3 a_Position;

uniform mat4 u_VP;
uniform mat4 u_Transform;

void main() {
    gl_Position = u_VP * u_Transform * vec4(a_Position, 1.0);
}
