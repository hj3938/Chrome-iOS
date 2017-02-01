// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ios/chrome/browser/ui/webui/net_export/net_export_ui.h"

#include <memory>
#include <string>

#include "base/bind.h"
#include "base/location.h"
#include "base/macros.h"
#include "base/memory/ptr_util.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "base/values.h"
#include "components/grit/components_resources.h"
#include "components/net_log/chrome_net_log.h"
#include "components/net_log/net_export_ui_constants.h"
#include "components/net_log/net_log_file_writer.h"
#include "ios/chrome/browser/application_context.h"
#include "ios/chrome/browser/browser_state/chrome_browser_state.h"
#include "ios/chrome/browser/chrome_url_constants.h"
#include "ios/chrome/browser/ui/show_mail_composer_util.h"
#include "ios/chrome/grit/ios_strings.h"
#include "ios/web/public/web_thread.h"
#include "ios/web/public/web_ui_ios_data_source.h"
#include "ios/web/public/webui/web_ui_ios.h"
#include "ios/web/public/webui/web_ui_ios_message_handler.h"
#include "net/log/net_log_capture_mode.h"
#include "net/url_request/url_request_context_getter.h"

namespace {

web::WebUIIOSDataSource* CreateNetExportHTMLSource() {
  web::WebUIIOSDataSource* source =
      web::WebUIIOSDataSource::Create(kChromeUINetExportHost);

  source->SetJsonPath("strings.js");
  source->AddResourcePath(net_log::kNetExportUIJS, IDR_NET_LOG_NET_EXPORT_JS);
  source->SetDefaultResource(IDR_NET_LOG_NET_EXPORT_HTML);
  return source;
}

// This class receives javascript messages from the renderer.
// Note that the WebUI infrastructure runs on the UI thread, therefore all of
// this class's public methods are expected to run on the UI thread. All static
// functions except SendEmail run on FILE_USER_BLOCKING thread.
class NetExportMessageHandler
    : public web::WebUIIOSMessageHandler,
      public base::SupportsWeakPtr<NetExportMessageHandler> {
 public:
  NetExportMessageHandler();
  ~NetExportMessageHandler() override;

  // WebUIMessageHandler implementation.
  void RegisterMessages() override;

  // Messages.
  void OnGetExportNetLogInfo(const base::ListValue* list);
  void OnStartNetLog(const base::ListValue* list);
  void OnStopNetLog(const base::ListValue* list);
  void OnSendNetLog(const base::ListValue* list);

 private:
  // If |log_path| is empty, then the NetLogFileWriter will use its default
  // log path.
  void StartNetLogThenNotifyUI(const base::FilePath& log_path,
                               net::NetLogCaptureMode capture_mode);

  void StopNetLogThenNotifyUI();

  // Send NetLog data via email.
  static void SendEmail(const base::FilePath& file_to_send);

  void NotifyUIWithNetLogFileWriterState(
      std::unique_ptr<base::DictionaryValue> file_writer_state);

  // Cache of GetApplicationContex()->GetNetLog()->net_log_file_writer(). This
  // is owned by ChromeNetLog which is owned by BrowserProcessImpl.
  net_log::NetLogFileWriter* net_log_file_writer_;

  base::WeakPtrFactory<NetExportMessageHandler> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(NetExportMessageHandler);
};

NetExportMessageHandler::NetExportMessageHandler()
    : net_log_file_writer_(
          GetApplicationContext()->GetNetLog()->net_log_file_writer()),
      weak_ptr_factory_(this) {
  net_log_file_writer_->SetTaskRunners(
      web::WebThread::GetTaskRunnerForThread(
          web::WebThread::FILE_USER_BLOCKING),
      web::WebThread::GetTaskRunnerForThread(web::WebThread::IO));
}

NetExportMessageHandler::~NetExportMessageHandler() {
  net_log_file_writer_->StopNetLog(
      nullptr, nullptr,
      base::Bind([](std::unique_ptr<base::DictionaryValue>) {}));
}

void NetExportMessageHandler::RegisterMessages() {
  DCHECK_CURRENTLY_ON(web::WebThread::UI);

  web_ui()->RegisterMessageCallback(
      net_log::kGetExportNetLogInfoHandler,
      base::Bind(&NetExportMessageHandler::OnGetExportNetLogInfo,
                 base::Unretained(this)));
  web_ui()->RegisterMessageCallback(
      net_log::kStartNetLogHandler,
      base::Bind(&NetExportMessageHandler::OnStartNetLog,
                 base::Unretained(this)));
  web_ui()->RegisterMessageCallback(
      net_log::kStopNetLogHandler,
      base::Bind(&NetExportMessageHandler::OnStopNetLog,
                 base::Unretained(this)));
  web_ui()->RegisterMessageCallback(
      net_log::kSendNetLogHandler,
      base::Bind(&NetExportMessageHandler::OnSendNetLog,
                 base::Unretained(this)));
}

void NetExportMessageHandler::OnGetExportNetLogInfo(
    const base::ListValue* list) {
  DCHECK_CURRENTLY_ON(web::WebThread::UI);
  net_log_file_writer_->GetState(
      base::Bind(&NetExportMessageHandler::NotifyUIWithNetLogFileWriterState,
                 weak_ptr_factory_.GetWeakPtr()));
}

void NetExportMessageHandler::OnStartNetLog(const base::ListValue* list) {
  DCHECK_CURRENTLY_ON(web::WebThread::UI);
  std::string capture_mode_string;
  bool result = list->GetString(0, &capture_mode_string);
  DCHECK(result);

  net::NetLogCaptureMode capture_mode =
      net_log::NetLogFileWriter::CaptureModeFromString(capture_mode_string);
  StartNetLogThenNotifyUI(base::FilePath(), capture_mode);
}

void NetExportMessageHandler::OnStopNetLog(const base::ListValue* list) {
  DCHECK_CURRENTLY_ON(web::WebThread::UI);
  StopNetLogThenNotifyUI();
}

void NetExportMessageHandler::OnSendNetLog(const base::ListValue* list) {
  DCHECK_CURRENTLY_ON(web::WebThread::UI);
  net_log_file_writer_->GetFilePathToCompletedLog(
      base::Bind(&NetExportMessageHandler::SendEmail));
}

void NetExportMessageHandler::StartNetLogThenNotifyUI(
    const base::FilePath& log_path,
    net::NetLogCaptureMode capture_mode) {
  DCHECK_CURRENTLY_ON(web::WebThread::UI);

  net_log_file_writer_->StartNetLog(
      log_path, capture_mode,
      base::Bind(&NetExportMessageHandler::NotifyUIWithNetLogFileWriterState,
                 weak_ptr_factory_.GetWeakPtr()));
}

void NetExportMessageHandler::StopNetLogThenNotifyUI() {
  DCHECK_CURRENTLY_ON(web::WebThread::UI);

  std::unique_ptr<base::DictionaryValue> ui_thread_polled_data;

  // TODO(crbug.com/438656): fill |ui_thread_polled_data| with browser-specific
  // polled data.

  net_log_file_writer_->StopNetLog(
      std::move(ui_thread_polled_data),
      GetApplicationContext()->GetSystemURLRequestContext(),
      base::Bind(&NetExportMessageHandler::NotifyUIWithNetLogFileWriterState,
                 weak_ptr_factory_.GetWeakPtr()));
}

// static
void NetExportMessageHandler::SendEmail(const base::FilePath& file_to_send) {
  if (file_to_send.empty())
    return;
  DCHECK_CURRENTLY_ON(web::WebThread::UI);

  std::string email;
  std::string subject = "net_internals_log";
  std::string title = "Issue number: ";
  std::string body =
      "Please add some informative text about the network issues.";
  ShowMailComposer(base::UTF8ToUTF16(email), base::UTF8ToUTF16(subject),
                   base::UTF8ToUTF16(body), base::UTF8ToUTF16(title),
                   file_to_send,
                   IDS_IOS_NET_EXPORT_NO_EMAIL_ACCOUNTS_ALERT_TITLE,
                   IDS_IOS_NET_EXPORT_NO_EMAIL_ACCOUNTS_ALERT_MESSAGE);
}

void NetExportMessageHandler::NotifyUIWithNetLogFileWriterState(
    std::unique_ptr<base::DictionaryValue> file_writer_state) {
  DCHECK_CURRENTLY_ON(web::WebThread::UI);
  web_ui()->CallJavascriptFunction(net_log::kOnExportNetLogInfoChanged,
                                   *file_writer_state);
}

}  // namespace

NetExportUI::NetExportUI(web::WebUIIOS* web_ui)
    : web::WebUIIOSController(web_ui) {
  web_ui->AddMessageHandler(base::MakeUnique<NetExportMessageHandler>());
  web::WebUIIOSDataSource::Add(ios::ChromeBrowserState::FromWebUIIOS(web_ui),
                               CreateNetExportHTMLSource());
}
