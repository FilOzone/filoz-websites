import { defineCollection } from 'astro:content'
import { glob } from 'astro/loaders'
import { z } from 'astro/zod'

const blog = defineCollection({
  loader: glob({ pattern: '**/*.md', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    description: z.string().optional(),
    date: z.coerce.date(),
    categories: z.array(z.string()).optional(),
    keywords: z.array(z.string()).optional(),
    slug: z.string().optional(),
    featured_image: z.string().optional(),
    wf_page: z.string().optional(),
  }),
})

export const collections = { blog }
