define([
  'i18n!plugins',
  'jquery' /* $ */,
  'jquery.instructure_misc_plugins' /* showIf */
], function(I18n, $) {
  var LEGEND_DEFAULT="Instructor can use Start/Stop Record button in sessions configured for recording."

  var LEGEND_ALL="Instructor can use Start/Stop Record button in all sessions."

  var LEGEND_HIDE="Hide Start/Stop Record button. Record all content shared in every session."

  $(document).ready(function() {
    $("#recordings_enabled_checkbox").change(function() {
      $("#recording_feature_options").showIf($(this).attr('checked'));
    }).change();

    displayRecordOptionCheckbox($('#settings_recording_options').val());
    displayLegend($('#settings_recording_options'));

    $('#settings_recording_options').change(function(){
      displayLegend(this);
      displayRecordOptionCheckbox($(this).val());
    })
  });

  function displayLegend(element){
    var option = $(element).val();
    var text;

    switch(option){
      case '1':
        text=LEGEND_DEFAULT
        break;
      case '2':
        text=LEGEND_ALL
        break;
      case '3':
        text=LEGEND_HIDE
        break;
      default:
        text=""
    }

    if($(document).has('#recording_option_legend').length>0){
      $(document).find('#recording_option_legend').remove();
    }

    $('<small class="help-text" id="recording_option_legend"><br>'+text+'</small>').insertAfter(element)
  }

  function displayRecordOptionCheckbox(value){
    value=='1' ? $("#recording_option_enabled").show() : $("#recording_option_enabled").hide()
  }
});
