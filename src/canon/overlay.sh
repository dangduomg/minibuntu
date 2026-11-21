overlay_dir=$build_dir/overlay

if [[ -d "$overlay_dir" ]]; then
    rm -r "$overlay_dir"
fi

mkdir -p "$overlay_dir"/{upper,work,merged}