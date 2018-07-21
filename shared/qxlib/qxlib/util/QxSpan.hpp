#ifndef QXSPAN_HPP
#define QXSPAN_HPP
#include <cstddef>

namespace qx {

template <typename T>
class span {
public:
    span(T *data, std::size_t size) :
        m_data(data), m_size(size)
    {}

    std::size_t size() const
    {
        return m_size;
    }

    T *get() const
    {
        return m_data;
    }

private:
    T *m_data;
    const std::size_t m_size;
};

template <typename T>
span<T> make_span(T *data, std::size_t size)
{
    return span<T>{data, size};
}

} // qx

#endif // QXSPAN_HPP
