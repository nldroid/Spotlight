using Toybox.Application;

class SpotlightApp extends Application.AppBase {

    var spotlight_view as SpotlightView;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {
        spotlight_view = new SpotlightView();
    }

    // onStop() is called when your application is exiting
    function onStop(state) {
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ spotlight_view ];
    }

    function onSettingsChanged() {
        spotlight_view.setupData();
        WatchUi.requestUpdate();
    }
}