library enums;

enum AgentState {BUSY,
                 IDLE,
                 PAUSE,
                 UNKNOWN}

enum AlertState {OFF,
                 ON}

enum AppState {LOADING,
               ERROR,
               READY}

enum Context {Home,
              Homeplus,
              CalendarEdit,
              Messages}

enum Widget {AgentInfo,
             CalendarEditor,
             ContactCalendar,
             ContactData,
             ContactSelector,
             MessageCompose,
             ReceptionCalendar,
             ReceptionCommands,
             ReceptionSelector,
             ReceptionAltNames,
             MessageArchiveFilter}