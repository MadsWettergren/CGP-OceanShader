Shader "Custom/WavesUV" {
	Properties {
		//Color of the Ocean
		_Color ("Color", Color) = (1,1,1,1)
		//Main texture (albedo)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		//Flow Map
		[NoScaleOffset] _FlowMap ("FlowMap (RG, A noise)", 2D) = "black"{}
		//Height Map
		[NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
		//Offsetting the UV to make the animation to change over time.
		_UJump("U jump per phase", Range(-.25, .25)) = .25
		_VJump("V jump per phase", Range(-.25, .25)) = .25
		//Tiling the distorted texture
		_Tiling("Tiling", Float) = 1
		//Animation speed for the distorted texture
		_Speed("Speed", Float) = 1
		//Strength of the flow, which is determined by the flow map
		_FlowStrength("Flow Strenght", Float) = 1
		//Offset of the flow animation
		_FlowOffset("Flow Offset", Float) = 0
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		//Vectors for the big waves, which controls the direction,
		//steepness and wavelenght. Can add as many waves as you want.
		_WaveA("Wave A(dir, steepness, wavelength)", Vector) = (1, 0, .5, 10)
		_WaveB("Wave B(dir, steepness, wavelength)", Vector) = (0, 1, .25, 20)
		_WaveC("Wave B(dir, steepness, wavelength)", Vector) = (1, 1, .15, 10)
		
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf Standard fullforwardshadows vertex:vert addshadow
		#pragma target 3.0

		#include "Flow.cginc"

		sampler2D _MainTex, _FlowMap, _NormalMap;
		float _UJump, _VJump, _Tiling, _Speed, _FlowStrength, _FlowOffset;
		float _HeightScale, _HeightScaleModulated;

		struct Input {
			float2 uv_MainTex;
		};

		half _Glossiness;
		half _Metallic;
		fixed4 _Color;
		float4 _WaveA, _WaveB, _WaveC;

		//Takes wave settings and original gridpoint. Has input/output for the tangent and binormal
		//Returns its point offset.
		float3 TrochoidalWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
		{
			float steepness = wave.z;
			float wavelength = wave.w;
			float k = 2 * UNITY_PI / wavelength;
			float c = sqrt(9.8 / k);
			float2 d = normalize(wave.xy);
			float f = k * (dot(d, p.xz) - c * _Time.y);
			float a = steepness / k;

			tangent += float3(-d.x * d.x * (steepness * sin(f)), d.x * (steepness * cos(f)), -d.x * d.y * (steepness * sin(f)));
			binormal += float3( -d.x * d.y * (steepness * sin(f)), d.y * (steepness * cos(f)), 1 - d.y * d.y * (steepness * sin(f)));
			
			return float3(d.x * (a * cos(f)), a * sin(f), d.y * (a *cos(f)));
		}
		//Adjusting verticies
		void vert(inout appdata_full vertexData) {
			float3 gridPoint = vertexData.vertex.xyz;
			float3 tangent = float3(1, 0, 0);
			float3 binormal = float3(0, 0, 1);
			float3 p = gridPoint;
			//Adding the waves from the properties
			p += TrochoidalWave(_WaveA, gridPoint, tangent, binormal);
			p += TrochoidalWave(_WaveB, gridPoint, tangent, binormal);
			p += TrochoidalWave(_WaveC, gridPoint, tangent, binormal);
			float3 normal = normalize(cross(binormal, tangent));
			vertexData.vertex.xyz = p;
			vertexData.normal = normal;
		}
		//Animating UV
		void surf (Input IN, inout SurfaceOutputStandard o) {
			float3 flow = tex2D(_FlowMap, IN.uv_MainTex).rgb;
			flow.xy = flow.xy * 2 - 1;
			flow *= _FlowStrength;
			flow *= _FlowStrength;
			float noise = tex2D(_FlowMap, IN.uv_MainTex).a;
			float time = _Time.y * _Speed + noise;
			float2 jump = float2(_UJump, _VJump);

			float3 uvwA = FlowUVW(IN.uv_MainTex, flow.xy, jump, _FlowOffset, _Tiling, time, false);
			float3 uvwB = FlowUVW(IN.uv_MainTex, flow.xy, jump, _FlowOffset, _Tiling, time, true);

			float3 normalA = UnpackNormal(tex2D(_NormalMap, uvwA.xy)) * uvwA.z;
			float3 normalB = UnpackNormal(tex2D(_NormalMap, uvwB.xy)) * uvwB.z;
			o.Normal = normalize(normalA + normalB);

			fixed4 texA = tex2D(_MainTex, uvwA.xy) * uvwA.z;
			fixed4 texB = tex2D(_MainTex, uvwB.xy) * uvwB.z;

			fixed4 c = (texA + texB) * _Color;
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}