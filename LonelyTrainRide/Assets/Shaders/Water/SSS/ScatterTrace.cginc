float ComputeSSS(in float3 vNormal, in float3 LightDir, in float3 EyeVec)
{   
//Get some normal shifted towards the eye
    float3 N = normalize(vNormal+EyeVec*0.2);
//Flip normal,dot with LightDir, so flanks wich get lit from behind recieve some light
    float LD0 = max(0.0,dot(float3(-1.0,-1.0,1.0)*N,LightDir));
//How much do we look into the Lightdirection ?
    float LD1 = max(0.0,dot(-EyeVec,LightDir)*0.6+0.4);
//How much does the wave flank faces towards us ?
    float LD2 = clamp(dot(EyeVec,N)*0.5+0.5,0.0,1.0);
     
//Mix it up until a nice value comes out :D
    float LD3 = LD0*LD1*LD2*LD2;
    return saturate(LD3*LD3*4.0+LD1*0.125);
}
