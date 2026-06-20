for process in \
    WidgetKitExtension \
    WidgetKitSimulator \
    NotificationCenter \
    chronod \
    cfprefsd
do
    pkill -x "$process" 2>/dev/null || true
done