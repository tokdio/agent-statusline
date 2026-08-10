# shellcheck shell=bash
# Model badge: tier-colored name + qualifiers in dim parens, e.g.
# "Fable 5 (max,think)" — effort colored as the spend dial it is (max=red,
# high=yellow, low=dim). Sets globals: model_col, model_short.

sl_model_add_qual() { # $1=color $2=text — appends to the module-local $qual
  local sep=""
  [ -n "$qual" ] && printf -v sep "%b,%b" "$DIM" "$RESET"
  local piece
  printf -v piece "%b%s%b" "$1" "$2" "$RESET"
  qual="$qual$sep$piece"
}

sl_model_badge() {
  local model=$1 effort=$2 fast=$3 think=$4
  model_short="${model% (1M context)}"

  local mcol
  case "$model" in
    *Fable*|*Mythos*) mcol=$M_FABLE ;;
    *Opus*)           mcol=$M_OPUS ;;
    *Sonnet*)         mcol=$M_SONNET ;;
    *Haiku*)          mcol=$M_HAIKU ;;
    *)                mcol=$YELLOW ;;
  esac
  local ecol
  case "$effort" in
    max)  ecol=$C_EFF_MAX ;;
    high) ecol=$C_EFF_HIGH ;;
    low)  ecol=$DIM ;;
    *)    ecol=$C_EFF_MED ;;
  esac

  printf -v model_col "%b%s%b" "$mcol" "$model_short" "$RESET"

  local qual=""
  [ -n "$effort" ]      && sl_model_add_qual "$ecol" "$effort"
  [ "$fast" = "true" ]  && sl_model_add_qual "$C_FAST" "fast"
  [ "$think" = "true" ] && sl_model_add_qual "$DIM" "think"
  [ -n "$qual" ] && printf -v model_col "%s %b(%b%s%b)%b" "$model_col" "$DIM" "$RESET" "$qual" "$DIM" "$RESET"
}
