uniform sampler2D baseMap;

void main ()
{
  vec3 c11 = texture2D(baseMap, gl_TexCoord[0].xy).xyz;  
  vec3 col = vec3(c11);
  float gray = (col.r + col.g + col.b) / 3.0;
  vec3 grayscale = vec3(gray);

  gl_FragColor = vec4(grayscale, 1);
}