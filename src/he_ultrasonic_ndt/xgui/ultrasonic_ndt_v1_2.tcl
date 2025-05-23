# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Group
  set Description [ipgui::add_group $IPINST -name "Description"]
  set_property tooltip {Description} ${Description}
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -parent ${Description}]
  ipgui::add_static_text $IPINST -name "Page 1" -parent ${Page_0} -text {Hitachi Energy Poland}
  ipgui::add_static_text $IPINST -name "Background" -parent ${Page_0} -text {Power Grid stability and reliability are critical to the success of our mission.}



}


