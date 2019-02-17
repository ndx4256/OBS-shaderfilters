// Drunk shader by Charles Fettinger  (https://github.com/Oncorporation)  2/2019
uniform float4x4 color_matrix;
uniform float glow_amount = 0.33;
uniform float blur_amount = 0.01;
uniform float luminance_floor = 0.33;
uniform float speed = 1.0;
uniform float4 glow_color;

// Gaussian Blur
float Gaussian(float x, float o) {
	const float pivalue = 3.1415926535897932384626433832795;
	return (1.0 / (o * sqrt(2.0 * pivalue))) * exp((-(x * x)) / (2 * (o * o)));
}

float4 InternalGaussianPrecalculated(float2 p_uv, float2 p_uvStep, int p_radius,
  texture2d p_image, float2 p_imageTexel,
  texture2d p_kernel, float2 p_kernelTexel) {
	float4 l_value = p_image.Sample(pointClampSampler, p_uv)
		* kernel.Sample(pointClampSampler, float2(0, 0)).r;
	float2 l_uvoffset = float2(0, 0);
	for (int k = 1; k <= p_radius; k++) {
		l_uvoffset += p_uvStep;
		float l_g = p_kernel.Sample(pointClampSampler, p_kernelTexel * k).r;
		float4 l_p = p_image.Sample(pointClampSampler, p_uv + l_uvoffset) * l_g;
		float4 l_n = p_image.Sample(pointClampSampler, p_uv - l_uvoffset) * l_g;
		l_value += l_p + l_n;
	}
	return l_value;
}

float4 mainImage(VertData v_in) : TARGET
{
	const float2 offsets[4] = 
	{
		-0.05,  0.066,
		-0.05, -0.066,
		0.05, -0.066,
		0.05,  0.066
	};

	float4 color = image.Sample(textureSampler, v_in.uv);
	float4 temp_color = color;

	float intensity = dot(color * 1 ,float3(0.299,0.587,0.114));
	float t = elapsed_time * speed;

	float glow = 0;
	if (intensity >= luminance_floor)
	{
		for (int n = 0; n < 4; n++){			
			//blur sample
			float4 ncolor = image.Sample(textureSampler, v_in.uv + (blur_amount * (1 + sin(t))) * offsets[n]) ;	
			//glow calc
			ncolor.a = clamp(ncolor.a * glow_amount, 0.0, 1.0);
			//temp_color = max(temp_color,ncolor) * glow_color ;//* ((1-ncolor.a) + color * ncolor.a);
			//temp_color += (ncolor * float4(glow_color.rbg, glow_amount));

			// use temp_color as floor, add glow, use highest alpha of blur pixels, then multiply by glow color
			// max is used to simulate addition of vector texture color
			temp_color = float4(max(temp_color.rgb,ncolor.rgb * glow_amount), max(temp_color.a, glow_amount)) * glow_color ;
		}
	}
	// grab lighter color
	return max(color,temp_color);
}

