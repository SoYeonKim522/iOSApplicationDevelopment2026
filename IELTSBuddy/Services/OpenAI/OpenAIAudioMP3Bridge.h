#ifndef OpenAIAudioMP3Bridge_h
#define OpenAIAudioMP3Bridge_h

#include <stdint.h>

/// Encodes interleaved 16-bit PCM to an MP3 file at `output_path`.
/// Returns 0 on success, non-zero on failure.
int openai_encode_pcm_to_mp3(
    const int16_t *samples,
    int sample_count,
    int sample_rate,
    int channels,
    const char *output_path
);

#endif /* OpenAIAudioMP3Bridge_h */
