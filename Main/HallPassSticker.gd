class_name HallPassSticker
extends Sticker

func init():
  sticker_id = "hall_pass"
  sticker_name = "Hall Pass"
  description = "Pass the grade if you have at least 50% of the required score"

func can_pass_grade(score: int, target: int) -> bool:
  return score >= ceil(target * 0.5)
