Soil carbon dynamics during drying vs. rewetting: importance of
antecedent moisture conditions
================

### How are soil carbon dynamics influenced by drying vs. wetting events?

-----

<img align="left" height = "300" width = "200" src="readme_files/Mopang_BC15.JPG">
<img align="center" height = "300" width = "300" src="readme_files/figure-gfm/map-1.png">

**Mopang Silt Loam**

-----

|                     | Soil 1   | Soil 2        |
| ------------------- | -------- | ------------- |
|                     | BC soil  | BC + Accusand |
| Texture             | SCL      | SL            |
| Total C (%)         | 8.34 %   | 5.56%         |
| Saturation moisture | 140% w/w | 100% w/w      |

``` 
moisture (5 levels): 100% saturated, 75% w/w, 50%, 35%, 5% (air dry)
    + field moist  
treatment (2 levels): wetting, drying  
texture (2 levels): sandy clay loam (SCL), sandy loam (SL)  
```

-----

### code/

`1-moisture_tracking.R`: tracks moisture in cores for pre-incubation
drying  
`2-hyprop`: water retention curves  
`3-picarro`: respiration  
`4-wsoc`: water soluble organic carbon analysis

### data/

`core_key` core assignments

`core_weights`

  - `initial` initial weights when cores were packed. includes empty
    weights
  - `Mass_tracking` core weights for pre-incubation drying. Also
    includes Picarro valve assignments.
  - ignore tabs marked `x_`

-----

<details>

<summary>Session Info</summary>

date: 2020-07-21

    #> R version 4.0.2 (2020-06-22)
    #> Platform: x86_64-apple-darwin17.0 (64-bit)
    #> Running under: macOS Catalina 10.15.6
    #> 
    #> Matrix products: default
    #> BLAS:   /Library/Frameworks/R.framework/Versions/4.0/Resources/lib/libRblas.dylib
    #> LAPACK: /Library/Frameworks/R.framework/Versions/4.0/Resources/lib/libRlapack.dylib
    #> 
    #> locale:
    #> [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
    #> 
    #> attached base packages:
    #> [1] stats     graphics  grDevices utils     datasets  methods   base     
    #> 
    #> loaded via a namespace (and not attached):
    #>  [1] compiler_4.0.2  magrittr_1.5    tools_4.0.2     htmltools_0.5.0
    #>  [5] yaml_2.2.1      stringi_1.4.6   rmarkdown_2.3   knitr_1.29     
    #>  [9] stringr_1.4.0   xfun_0.15       digest_0.6.25   rlang_0.4.7    
    #> [13] evaluate_0.14

</details>
