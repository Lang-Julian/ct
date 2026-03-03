# ct config — define your own tasks
# Copy to ~/.ct/config.zsh
#
# Format: key  "Label;R;G;B;icon_file"
# The icon_file maps to ~/.ct/icons/<icon_file>.png
# If the icon doesn't exist, it's auto-generated on first use.

_CT_TASKS+=(
    # myapp     "My App;80;140;220;myapp"
    # deploy    "Production Deploy;220;60;60;deploy"
    # review    "Code Review;100;180;100;review"
)
