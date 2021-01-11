Soil carbon dynamics during drying vs. rewetting: importance of
antecedent moisture conditions
================

### How are soil carbon dynamics influenced by drying vs. wetting events?

This repository contains data and code for the manuscript: **Soil carbon
dynamics during drying vs. rewetting: importance of antecedent moisture
conditions**

Kaizad F. Patel et al. 

-----

<img align="left" height = "300" width = "200" src="readme_files/Mopang_BC15.JPG">
<img align="center" height = "300" width = "300" src="readme_files/figure-gfm/map-1.png">

**Mopang Silt Loam**

-----

### EXPERIMENTAL SETUP

|                     | Soil 1   | Soil 2        |
| ------------------- | -------- | ------------- |
|                     | BC soil  | BC + Accusand |
| Texture             | SCL      | SL            |
| Total C (%)         | 8.34 %   | 5.56%         |
| Saturation moisture | 140% w/w | 100% w/w      |

  - moisture (5 levels):
    1.  100% saturated,
    2.  75%,
    3.  50%,
    4.  35%,
    5.  5% (air dry)
    <!-- end list -->
      - *plus field moist*  
  - treatment (2 levels):
    1.  wetting,
    2.  drying  
  - texture (2 levels):
    1.  sandy clay loam (SCL),
    2.  sandy loam (SL)

-----

### DIRECTORY STRUCTURE

``` r
home
|------ code/
|------ data/
|         |------ fticr/
|         |------ nmr_peaks/
|         |------ nmr_spectra/
|         |------ picarro_data/
|         |------ processed/
|         |------ wrc/
|         |------ wsoc_data/
|------ markdown/
|------ outputs/
|
|------ hysteresis.Rproj
|------ README
  
```

-----

<details>

<summary>Session Info</summary>

date: 2021-01-11

    #> R version 4.0.2 (2020-06-22)
    #> Platform: x86_64-apple-darwin17.0 (64-bit)
    #> Running under: macOS Catalina 10.15.7
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
    #>  [9] stringr_1.4.0   xfun_0.16       digest_0.6.25   rlang_0.4.7    
    #> [13] evaluate_0.14

</details>
