#version 330 core


//texture
uniform sampler2D tex;
uniform sampler2D normaltex;

//lighting
uniform vec3 lightpos;
uniform vec3 lightcolor;

//camera
uniform vec3 camerapos;


//inputs from vshader
in vec2 tcoord;
in vec3 tnormal;
in vec3 fragpos;

//outputs
out vec4 color;

float kA = 0.1;
float kD = 1.0;
float kS = 1.0;

float kLS = 0.1;
float kTS = 1.0;

void main() {

    vec3 nnormalp = normalize(tnormal);
    vec3 lightdir = normalize(lightpos-fragpos);
    vec3 cameradir = normalize(camerapos-fragpos);




    //backface culling
    float culling = dot(nnormalp, cameradir);
    // if (culling <= 0) {
    //         discard;
    // }


    vec3 nmap = vec3(texture(normaltex, tcoord*kTS));
    vec3 nnormal = normalize(nmap*nnormalp);
    // vec3 nnormal = nnormalp;

    vec4 dc = texture(tex, tcoord*kTS);

    float lightdist = (kLS)*distance(fragpos, lightpos);

    float ambient = kA;
    float diffuse = max(dot(nnormal, lightdir), 0) * kD / lightdist;
    float spec = pow(max(dot(cameradir, reflect(-lightdir, nnormal)), 0.0), 1) * kS / lightdist;
    



    // color = (ambient+diffuse+spec)*vec4(lightcolor, 1)*dc;
    color = vec4(1,1,1,1);
}
