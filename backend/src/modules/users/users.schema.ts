import { z } from 'zod';

export const updateMeSchema = z
  .object({
    displayName: z
      .string()
      .min(1, 'Display name cannot be empty')
      .max(50, 'Display name must be at most 50 characters')
      .trim()
      .optional(),
    avatarUrl: z
      .string()
      .url('Invalid avatar URL')
      .optional()
      .nullable(),
  })
  .refine((data) => data.displayName !== undefined || data.avatarUrl !== undefined, {
    message: 'At least one field (displayName or avatarUrl) must be provided for update',
  });

export const searchUsersSchema = z.object({
  q: z
    .string({ required_error: 'Query parameter q is required' })
    .min(1, 'Search query must be at least 1 character')
    .max(50, 'Search query must be at most 50 characters')
    .trim(),
  limit: z
    .coerce
    .number()
    .min(1)
    .max(50)
    .default(20),
});

export type UpdateMeInput = z.infer<typeof updateMeSchema>;
export type SearchUsersInput = z.infer<typeof searchUsersSchema>;
