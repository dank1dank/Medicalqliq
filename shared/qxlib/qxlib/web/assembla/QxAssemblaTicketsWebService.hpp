#ifndef QXASSEMBLATICKETSWEBSERVICE_HPP
#define QXASSEMBLATICKETSWEBSERVICE_HPP
#include "optional.hpp"
#include "QxAssemblaBaseWebService.hpp"

namespace qx {
namespace web {

class AssemblaTicketsWebService : public AssemblaBaseWebService
{
public:
    enum class Report {
        AllTickets = 0,
        ActiveTicketsOrderByMilestone = 1,
        ActiveTicketsOrderByComponent = 2,
        ActiveTicketsOrderByUser = 3,
        ClosedTicketsOrderByMilestone = 4,
        ClosedTicketsOrderByComponent = 5,
        ClosedTicketsOrderByDate = 6,
        AllUsersTickets = 7,
        AllUsersActiveTickets = 8,
        AllUsersClosedTickets = 9,
        AllUsersFollowedTickets = 10
    };
    enum class SortOrder {
        Ascending,
        Descending
    };

    struct Params {
        std::experimental::optional<Report> report;
        std::experimental::optional<int> page;
        std::experimental::optional<int> perPage;
        std::experimental::optional<SortOrder> sortOrder;
    };

    AssemblaTicketsWebService(WebClient *webClient = nullptr);

    typedef std::function<void(const QliqWebError& error, const AssemblaTicket& ticket)> TicketResultCallback;
    void create(const AssemblaTicket& ticket, TicketResultCallback resultCallback, IsCancelledFunction isCancelledFun = IsCancelledFunction());

    void ticketByNumber(int number, TicketResultCallback resultCallback);
    void ticketById(int id, TicketResultCallback resultCallback);

    typedef std::function<void(const QliqWebError& error, const std::vector<AssemblaTicket>& users)> TicketsResultCallback;
    void tickets(const Params& params, TicketsResultCallback resultCallback, IsCancelledFunction isCancelledFun = IsCancelledFunction());

    void delete_(int number, DeleteResultCallback resultCallback);
    void delete_(const AssemblaTicket& ticket, DeleteResultCallback resultCallback);

private:
    void handleTicketsResponse(const QliqWebError& error, const json11::Json& json, const TicketsResultCallback& resultCallback);
    void handleTicketResponse(const QliqWebError& error, const json11::Json& json, const TicketResultCallback& resultCallback);
};

} // web
} // qx

#endif // QXASSEMBLATICKETSWEBSERVICE_HPP
