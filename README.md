Check out my other stuff [here](https://illsen.com/links/).

## Here’s How You Can Set Up the Shader:

### Create Sprite:
- Add a `Sprite2D` node and assign your texture to it.

### Create Inverted Sprite:
- Add another `Sprite2D` node.
- Assign a **color-inverted** version of the texture from step one to this sprite.
- Apply the shader material to this color-inverted sprite.

### Ensure Both Sprites are Aligned:
- Position the color-inverted sprite exactly on top of the original sprite.

### Configure the Shader Parameters:
- Adjust the `glow_position`, `glow_size`, `glow_strength`, `glow_intensity`, and other parameters to fit your new sprite.
- If you want the glow to pulsate, set the `pulsate` parameter to `true` and configure the `pulsation_speed`, `glow_intensity_start`, and `glow_intensity_stop` parameters.
