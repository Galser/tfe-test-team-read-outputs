# Example of apply in newly crated workspace

```Terraform
Terraform v0.13.5
Initializing plugins and modules...
random_pet.demo: Creating...
random_pet.demo: Creation complete after 0s [id=game-cheetah]

Warning: Interpolation-only expressions are deprecated

  on maint.tf line 4, in output "demo":
   4:   value = "${random_pet.demo.id}"

Terraform 0.11 and earlier required all non-constant expressions to be
provided via interpolation syntax, but this pattern is now deprecated. To
silence this warning, remove the "${ sequence from the start and the }"
sequence from the end of this expression, leaving just the inner expression.

Template interpolation syntax is still used to construct strings from
expressions when the template includes multiple interpolation sequences or a
mixture of literal strings and interpolations. This deprecation applies only
to templates that consist entirely of a single interpolation sequence.


Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

demo = game-cheetah
```

