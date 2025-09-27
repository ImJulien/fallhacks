class_name Ingredient

enum PrepState {
	FULL,
	CHOPPED
}

enum CookState {
	RAW,
	COOKED,
	BURNED
}

var ingredient_name := 'IngredientTest'
var doneness: float = 0.0
var cookState: CookState
var prepState: PrepState
