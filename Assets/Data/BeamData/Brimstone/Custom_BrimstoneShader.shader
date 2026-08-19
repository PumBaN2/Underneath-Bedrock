Shader "Custom/Brimstone"
{
    Properties
    {
        // --- COLORS ---
        [HDR] _CoreColor ("Core Color", Color) = (1.0, 0.05, 0.05, 1.0)    // Pure Red Core
        [HDR] _GlowColor ("Glow Color", Color) = (0.6, 0.0, 0.0, 0.4)     // Soft Blood Glow
        [HDR] _HotSpotColor ("Hot Spot Color", Color) = (1.0, 0.8, 0.3, 1.0) // Bright Yellow/White pulse

        // --- GEOMETRY & SHAPE ---
        _BeamWidth ("Beam Width", Range(0.01, 0.6)) = 0.15
        _GlowWidth ("Glow Width", Range(0.1, 1.0)) = 0.4
        _PixelSize ("Pixelated Edge Size", Range(0.005, 0.1)) = 0.02

        // --- DYNAMIC ANIMATION ---
        _ScrollSpeedX ("Wave Scroll X", Range(-5, 5)) = 0.5
        _ScrollSpeedY ("Wave Scroll Y", Range(-5, 5)) = 0.5
        _PulseSpeed ("Hot Spot Speed", Range(-10, 10)) = 3.0
        _HotSpotDensity ("Hot Spot Density", Range(0.5, 4.0)) = 2.0
        
        // --- NOISE INPUT ---
        _NoiseTex ("Noise Texture (Grayscale)", 2D) = "white" {}
        
        // --- STENCIL (For Room/Wall clipping in Isaac) ---
        _Stencil ("Stencil Ref", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Float) = 8 // NotEqual
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Float) = 0 // Keep
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" }
        LOD 100
        
        // Stencil Setup (Critical for Isaac room transitions)
        Stencil
        {
            Ref [_Stencil]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            Comp [_StencilComp]
            Pass [_StencilOp]
        }

        // Transparent blending setup
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // Properties from the Inspector
            fixed4 _CoreColor;
            fixed4 _GlowColor;
            fixed4 _HotSpotColor;
            
            float _BeamWidth;
            float _GlowWidth;
            float _PixelSize;
            
            float _ScrollSpeedX;
            float _ScrollSpeedY;
            float _PulseSpeed;
            float _HotSpotDensity;
            
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                // Apply tiling and scrolling to the UVs
                o.uv.xy = v.uv.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
                o.uv.x += _Time.y * _ScrollSpeedX * 0.2;
                o.uv.y += _Time.y * _ScrollSpeedY * 0.2;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 1. CENTER THE UVs (0 = middle, -0.5 to 0.5 = edges)
                float2 uv = i.uv - 0.5;

                // 2. CALCULATE BLOCKY/PIXELATED EDGE DISTORTION
                // This floors the Y coordinate, creating the "stepped" pixel look of Repentance
                float steppedY = floor(uv.y / _PixelSize) * _PixelSize;
                
                // Sample noise and apply it to the blocky edge
                float noise = tex2D(_NoiseTex, float2(uv.x * 3.0, _Time.y * 0.5)).r;
                float noiseOffset = (noise - 0.5) * 0.08; // Small wobble
                
                // Calculate the distance from the center of the beam using the stepped Y
                float dist = abs(steppedY - noiseOffset);

                // 3. BUILD THE PULSING HOT SPOTS (The bright yellow/white streaks)
                // Creates a traveling sine wave from left to right
                float pulse = sin((uv.x * _HotSpotDensity * 12.0) - (_Time.y * _PulseSpeed));
                float pulseStrength = 0.6 + (pulse * 0.5 + 0.5) * 0.4; // Maps to 0.6 to 1.0

                // 4. LAYER THE VISUALS
                
                // LAYER 1: OUTER BLOOD GLOW (Soft, wide, dim red)
                float glowMask = 1.0 - smoothstep(0.0, _GlowWidth, dist);
                fixed4 glow = _GlowColor * glowMask;

                // LAYER 2: SOLID RED CORE (Sharp, thick, saturated red)
                float coreMask = 1.0 - smoothstep(0.0, _BeamWidth, dist);
                // The core pulses in brightness as the hot spots pass over it
                fixed4 core = _CoreColor * coreMask * pulseStrength;

                // LAYER 3: HOT SPOT HIGHLIGHTS (Bright yellow/white streaks)
                // Only appears where the pulse is high AND inside the core
                float hotMask = smoothstep(0.65, 1.0, pulse); 
                fixed4 hotSpot = _HotSpotColor * coreMask * hotMask;

                // 5. FINAL COMPOSITE
                fixed4 col = glow + core + hotSpot;
                
                return col;
            }
            ENDCG
        }
    }
}