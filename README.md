# hysteresis
drying and wetting soils to various suctions


||Soil_type 1|Soil_type 2|
|--|--|--|
Texture| SCL | SL|
TC| 8.34 %| 5.56% |
Saturation moisture| 140% w/w| 100% w/w

	moisture (5 levels): saturated, 100% w/w, 75%, 50%, dry
		+ field moist
	
	treatment (2 levels): wetting, drying

## script
`1-moisture_tracking.R`:	tracks moisture in cores for pre-incubation drying


## folders - data
`core_key` core assignments

`core_weights` 

 - `initial` initial weights when cores were packed. includes empty weights
 - `Mass_tracking` core weights for pre-incubation drying. Also includes Picarro valve assignments.
 - ignore tabs marked `x_`
 
 
 


