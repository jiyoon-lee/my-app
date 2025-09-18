import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Docker를 위한 Standalone 출력 모드
  output: 'standalone',
  
  // 성능 최적화
  compress: true,
  poweredByHeader: false,
  
  // 이미지 최적화
  images: {
    formats: ['image/webp', 'image/avif'],
    deviceSizes: [640, 750, 828, 1080, 1200, 1920, 2048, 3840],
    imageSizes: [16, 32, 48, 64, 96, 128, 256, 384],
  },
  
  // 실험적 기능
  experimental: {
    optimizeCss: true,
    optimizePackageImports: ['lucide-react', '@radix-ui/react-icons'],
  },
  
  // 빌드 최적화
  eslint: {
    ignoreDuringBuilds: false,
  },
  
  // TypeScript 설정
  typescript: {
    ignoreBuildErrors: false,
  },
  
  // 환경 변수 설정
  env: {
    CUSTOM_KEY: process.env.CUSTOM_KEY,
  },
};

export default nextConfig;