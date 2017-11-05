# Fireflies
load_library :control_panel
COL_NAME = %w[sand rain green water black light].freeze
COL_HEX = [0xF2E8C4, 0x98D9B6, 0x3EC9A7, 0x2B879E, 0x616668, 0xc9f202]
PALETTE = COL_NAME.zip(COL_HEX).to_h

attr_reader :panel, :hide, :mask_image, :flies, :spot_image

def settings
  size 1024, 480, P2D
  smooth
end

def setup
  sketch_title 'Fireflies'
  control_panel do |c|
    c.slider(:speed, 0..20, 5)
    c.slider(:tail_length, 0..400, 30)
    c.slider(:rotation_max, 0..30, 7)
    c.slider(:target_radius, 5...100, 20)
    c.slider(:spot_distance, 5..200, 80)
    c.button :reset!
    @panel = c
  end
  @hide = false
  @spot_image = create_spot
  @background = load_image(data_path('background.png'))
  @mask_image = load_image(data_path('mask.png'))
  @spots = load_spots(mask_image, 4)
  reset!
end

def reset!
  @flies = (0..100).map { create_fly }
end

def draw
  unless hide
    panel.show
    @hide = true
  end
  image @background, 0, 0
  draw_lights
  draw_flies
end

def draw_lights
  lights = create_graphics width, height, P2D
  lights.begin_draw
  flies.each do |fly|
    lights.push_matrix
    lights.translate fly.pos.x, fly.pos.y
    lights.image spot_image, 0, 0
    lights.pop_matrix
  end
  lights.end_draw
  mask_image.mask lights
  image mask_image, 0, 0
end

def draw_flies
  rotation_max = @rotation_max / 100 * TWO_PI
  flies.each do |fly|
    # check if point reached
    if fly.pos.dist(fly.to_pos) < @target_radius
      fly.to_pos = find_spot_near fly.pos, @spot_distance
    end
    # set new rotation
    to_rotation = (fly.to_pos - fly.pos).heading
    to_rotation = find_nearest_rotation(fly.rotation, to_rotation)
    # rotate to new direction
    if fly.rotation < to_rotation
      fly.rotation += rotation_max
      fly.rotation = to_rotation if fly.rotation > to_rotation
    else
      fly.rotation -= rotation_max
      fly.rotation = to_rotation if fly.rotation < to_rotation
    end
    # add tail position
    fly.positions << Vec2D.new(fly.pos.x, fly.pos.y)
    fly.positions.shift while fly.positions.size > @tail_length
    # set fly position
    fly.pos += Vec2D.from_angle(fly.rotation) * @speed
    # draw fly tail
    draw_tail fly.positions
    # draw fly
    no_stroke
    fill 201, 242, 2
    push_matrix
    translate fly.pos.x, fly.pos.y
    ellipse 0, 0, 5, 5
    pop_matrix
  end
end

Fly = Struct.new(:pos, :to_pos, :rotation, :positions)

def create_fly
  spot = rand_spot
  to_spot = find_spot_near spot, @spot_distance
  rotation = rand * TWO_PI
  Fly.new(spot, to_spot, rotation, [])
end

def draw_tail(positions)
  return unless positions && !positions.empty?
  alpha_add = 255 / positions.size
  positions.each_with_index do |position, i|
    stroke(255, i * alpha_add)
    next unless i < positions.size - 2
    line(position.x, position.y, positions[i + 1].x, positions[i + 1].y)
  end
end

def load_spots(mask, accuracy = 4)
  spots = []
  mask.load_pixels
  corner_color = mask.pixels[0]
  grid(mask.width, mask.height, accuracy, accuracy) do |x, y|
    next if mask.pixels[y * mask.width + x] == corner_color
    spots << Vec2D.new(x, y)
  end
  spots
end

def rand_spot
  @spots.sample
end

def find_spot_near(position, distance)
  spot = nil
  spot = rand_spot until spot && spot.dist(position) < distance
  spot
end

def find_nearest_rotation(from, to)
  dif = (to - from) % TWO_PI
  if dif != dif % PI
    dif = dif < 0 ? dif + TWO_PI : dif - TWO_PI
  end
  from + dif
end

def create_spot
  size = 30
  glow = create_graphics size, size, P2D
  glow.begin_draw
  glow.no_stroke
  glow.fill 255, 60
  # glow.fill 255, 40
  glow.ellipse size / 2, size / 2, size, size
  glow.filter BLUR, 4
  glow.end_draw
  glow
end
