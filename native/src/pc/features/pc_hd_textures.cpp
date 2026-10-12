#include "pc/pc_hd_textures.h"

// HD texture packs disabled for RK3326 GLES port
void pc_hd_textures_init(const char* userPath) { (void)userPath; }
void pc_hd_textures_frame_end(unsigned int frame) { (void)frame; }
bool cos_hd_textures_set_enabled(bool enabled) { (void)enabled; return false; }
bool cos_hd_textures_enabled(void) { return false; }
void pc_hd_textures_set_stats_every(unsigned int frames) { (void)frames; }
