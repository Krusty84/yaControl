for process in \
    WidgetKitExtension \
    WidgetKitSimulator \
    NotificationCenter \
	pkd \
	Dock \
    chronod \
    cfprefsd
do
    pkill -x "$process" 2>/dev/null || true
done