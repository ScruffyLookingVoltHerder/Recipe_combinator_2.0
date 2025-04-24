local default_gui = data.raw["gui-style"].default


default_gui["outer_frame"] =
{
  type = "frame_style",
  parent = "invisible_frame",
  graphical_set = { shadow = default_shadow }
}

default_gui["inner_frame_in_outer_frame"] =
{
  type = "frame_style",
  graphical_set =
  {
    base = {position = {0, 0}, corner_size = 8}
    -- no shadow in inner frame as it is managed by outer frame
    -- this is to avoid shows of frames that are touching to interact
  }
}