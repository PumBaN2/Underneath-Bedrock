Shader "Custom/ReverseEngineered_BeamFire_Golden"
{
    Properties
    {
        // --- CORE TEXTURES ---
        _MainTex ("Main Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}
        
        // --- COLORS ---
        _CoreColor ("Core Color", Color) = (1.0, 0.9, 0.3, 1.0)   // Bright Gold
        _GlowColor ("Outer Glow Color", Color) = (1.0, 0.5, 0.0, 0.6) // Orange Glow
        
        // --- YOUR ORIGINAL SHAPE LOGIC ---
        _LineSize ("Beam Thickness", Range(0, 1)) = 0.3
        _Mitigation ("Waviness Strength", Range(0, 2)) = 0.2
        _Offset ("Vertical Offset", Range(-1, 1)) = 0.5
        _Speed ("Wave Scroll Speed", Float) = 2.0
        
        // --- NEW DYNAMIC PULSE ---
        _PulseSpeed ("Pulse Flow Speed", Range(-5, 5)) = 1.5
        
        // --- SCROLLING ---
        _ScrollX ("Scroll Speed X", Range(-5, 5)) = 0
        _ScrollY ("Scroll Speed Y", Range(-5, 5)) = 0

        // --- BLENDING & STENCIL ---
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend Mode", Float) = 5
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend Mode", Float) = 10

        _Stencil ("Stencil Ref", Float) = 255
        _StencilReadMask ("Stencil Read Mask", Float) = 255
        _StencilWriteMask ("Stencil Write Mask", Float) = 255
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Stencil Comparison", Float) = 8
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilOp ("Stencil Operation", Float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 100
        
        Stencil
        {
            Ref [_Stencil]
            ReadMask [_StencilReadMask]
            WriteMask [_StencilWriteMask]
            Comp [_StencilComp]
            Pass [_StencilOp]
        }

        Blend [_SrcBlend] [_DstBlend]
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
                float2 uv_Main : TEXCOORD0;
                float2 uv_Noise : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NoiseTex;
            float4 _NoiseTex_ST;
            
            fixed4 _CoreColor;
            fixed4 _GlowColor;
            
            float _LineSize;
            float _Mitigation;
            float _Offset;
            float _Speed;
            float _PulseSpeed;
            
            float _ScrollX;
            float _ScrollY;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                
                // MAIN TEXTURE UV - Static to keep the beam permanently visible
                o.uv_Main.xy = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                // NOISE TEXTURE UV - Used for the wavy shape
                // We apply the speed to slide the noise horizontally/vertically
                o.uv_Noise.xy = v.uv.xy * _NoiseTex_ST.xy + _NoiseTex_ST.zw;
                o.uv_Noise.x += _Time.y * _ScrollX * 0.5;
                o.uv_Noise.y += _Time.y * _ScrollY * 0.5;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // === YOUR ORIGINAL SHAPE CALCULATION (KEPT INTACT) ===
                float noise = tex2D(_NoiseTex, i.uv_Noise).r;
                float targetPos = (noise * _Mitigation) + _Offset;
                float dist = abs(i.uv_Main.y - targetPos);
                
                // Create a slight glow layer (Soft edges)
                float glowMask = 1.0 - smoothstep(0.0, _LineSize * 1.5, dist);
                // Create the solid bright core layer (Hard edges)
                float coreMask = 1.0 - smoothstep(0.0, _LineSize, dist);
                
                // === NEW PULSE LOGIC (To match the golden image) ===
                // This creates a bright "hotspot" that slides left to right
                float pulse = sin((i.uv_Main.x * 20.0) - (_Time.y * _PulseSpeed));
                float pulseIntensity = 0.6 + (pulse * 0.5 + 0.5) * 0.4;

                // === LAYER COLORING ===
                // Glow Layer (Orange/Yellow, soft)
                fixed4 glow = _GlowColor * glowMask * pulseIntensity;
                // Core Layer (Pure Bright White/Gold, solid)
                fixed4 core = _CoreColor * coreMask * pulseIntensity;
                // High-intensity layer (Pure White)
                fixed4 brightCore = fixed4(1.0, 1.0, 0.9, 1.0) * coreMask * smoothstep(0.5, 1.0, pulse);

                // === FINAL OUTPUT ===
                fixed4 col = glow + core + brightCore;
                return col;
            }
            ENDCG
        }
    }
}