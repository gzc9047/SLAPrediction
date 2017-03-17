{
    if ($2 < $4) {
        max = $4;
    } else {
        max = $2
    }
    printf("%0.16f %f\n", $1 * $3, max);
}
