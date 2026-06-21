#include "OpenAIAudioMP3Bridge.h"

#include "Shine/layer3.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int shine_bitrate_for(int sample_rate) {
    if (shine_check_config(sample_rate, 128) >= 0) {
        return 128;
    }
    if (shine_check_config(sample_rate, 64) >= 0) {
        return 64;
    }
    return -1;
}

int openai_encode_pcm_to_mp3(
    const int16_t *samples,
    int sample_count,
    int sample_rate,
    int channels,
    const char *output_path
) {
    if (samples == NULL || sample_count <= 0 || output_path == NULL) {
        return -1;
    }

    if (channels < 1) {
        channels = 1;
    } else if (channels > 2) {
        channels = 2;
    }

    int bitrate = shine_bitrate_for(sample_rate);
    if (bitrate < 0) {
        return -2;
    }

    shine_config_t config;
    config.wave.channels = channels == 1 ? PCM_MONO : PCM_STEREO;
    config.wave.samplerate = sample_rate;
    shine_set_config_mpeg_defaults(&config.mpeg);
    config.mpeg.bitr = bitrate;
    if (channels == 1) {
        config.mpeg.mode = MONO;
    }

    shine_t encoder = shine_initialise(&config);
    if (encoder == NULL) {
        return -3;
    }

    FILE *out = fopen(output_path, "wb");
    if (out == NULL) {
        shine_close(encoder);
        return -4;
    }

    const int samples_per_pass = shine_samples_per_pass(encoder);
    const int frame_pcm_samples = samples_per_pass * channels;
    int16_t *frame = (int16_t *)calloc((size_t)frame_pcm_samples, sizeof(int16_t));
    if (frame == NULL) {
        fclose(out);
        shine_close(encoder);
        return -5;
    }

    int processed = 0;
    while (processed < sample_count) {
        const int remaining = sample_count - processed;
        const int to_copy = remaining < frame_pcm_samples ? remaining : frame_pcm_samples;

        memset(frame, 0, (size_t)frame_pcm_samples * sizeof(int16_t));
        memcpy(frame, samples + processed, (size_t)to_copy * sizeof(int16_t));
        processed += to_copy;

        int written = 0;
        unsigned char *mp3 = shine_encode_buffer_interleaved(encoder, frame, &written);
        if (mp3 != NULL && written > 0) {
            fwrite(mp3, 1, (size_t)written, out);
        }

        if (to_copy < frame_pcm_samples) {
            break;
        }
    }

    int flush_written = 0;
    unsigned char *flush = shine_flush(encoder, &flush_written);
    if (flush != NULL && flush_written > 0) {
        fwrite(flush, 1, (size_t)flush_written, out);
    }

    free(frame);
    fclose(out);
    shine_close(encoder);
    return 0;
}
