import { z } from 'zod';

export const callInviteSchema = z.object({
  calleeId: z
    .string({ required_error: 'calleeId is required' })
    .min(1, 'calleeId cannot be empty')
    .trim(),
  callType: z.enum(['audio', 'video']).default('video'),
});

export const callAcceptSchema = z.object({
  callId: z
    .string({ required_error: 'callId is required' })
    .min(1, 'callId cannot be empty')
    .trim(),
});

export const callRejectSchema = z.object({
  callId: z
    .string({ required_error: 'callId is required' })
    .min(1, 'callId cannot be empty')
    .trim(),
  reason: z.string().optional().default('Call rejected by user'),
});

export const callOfferSchema = z.object({
  callId: z
    .string({ required_error: 'callId is required' })
    .min(1, 'callId cannot be empty')
    .trim(),
  sdp: z.union([z.record(z.unknown()), z.string()]),
});

export const callAnswerSchema = z.object({
  callId: z
    .string({ required_error: 'callId is required' })
    .min(1, 'callId cannot be empty')
    .trim(),
  sdp: z.union([z.record(z.unknown()), z.string()]),
});

export const callIceCandidateSchema = z.object({
  callId: z
    .string({ required_error: 'callId is required' })
    .min(1, 'callId cannot be empty')
    .trim(),
  candidate: z.union([z.record(z.unknown()), z.string()]),
});

export const callHangupSchema = z.object({
  callId: z
    .string({ required_error: 'callId is required' })
    .min(1, 'callId cannot be empty')
    .trim(),
  reason: z.string().optional().default('Call ended'),
});
