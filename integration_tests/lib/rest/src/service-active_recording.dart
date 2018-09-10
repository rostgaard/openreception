part of ort.service;

/**
 *
 */
abstract class ActiveRecording {
  static Logger log = Logger('service.CallFlowControl.ActiveRecording');

  /**
   *
   */
  static Future listEmpty(service.CallFlowControl callFlow) async =>
      expect(await callFlow.activeRecordings(), isEmpty);

  /**
   *
   */
  static void getNonExisting(service.CallFlowControl callFlow) => expect(
      callFlow.activeRecording('none'),
      throwsA(const TypeMatcher<storage.NotFound>()));
}
