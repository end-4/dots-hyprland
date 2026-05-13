import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://dots-hyprland.vercel.app',
  integrations: [
    starlight({
      title: 'dots-hyprland',
      description: 'Documentation for omsenjalia/dots-hyprland — a fork of end-4/dots-hyprland (illogical-impulse)',
      logo: {
        src: './src/assets/logo.svg',
        replacesTitle: false,
      },
      social: [
        { icon: 'github', label: 'GitHub', href: 'https://github.com/omsenjalia/dots-hyprland' },
      ],
      editLink: {
        baseUrl: 'https://github.com/omsenjalia/dots-hyprland/edit/main/docs/',
      },
      customCss: ['./src/styles/custom.css'],
      sidebar: [
        {
          label: 'Guide',
          autogenerate: { directory: 'guide' },
        },
        {
          label: 'Custom Additions',
          autogenerate: { directory: 'custom' },
        },
        {
          label: 'AI Agent Guide',
          autogenerate: { directory: 'ai-agents' },
        },
      ],
      defaultLocale: 'root',
      locales: { root: { label: 'English', lang: 'en' } },
      lastUpdated: true,
    }),
  ],
});
