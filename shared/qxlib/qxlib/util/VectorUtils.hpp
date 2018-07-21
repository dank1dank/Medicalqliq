#pragma once

#include <vector>
#include <iterator>
#include <algorithm>

namespace VectorUtils {
    template<typename T, class UnaryPredicate>
    std::vector<T> filter(const std::vector<T> & original, UnaryPredicate pred)
    {
	std::vector<T> filtered;
	std::copy_if(begin(original), end(original), std::back_inserter(filtered), pred);
	return filtered;
    }

    template<typename T2, typename T1, class UnaryOperation>
    std::vector<T2> map(const std::vector<T1> & original, UnaryOperation mappingFunction)
    {
	std::vector<T2> mapped;
	std::transform(begin(original), end(original), std::back_inserter(mapped), mappingFunction);
	return mapped;
    }

    template<typename T>
    void append(std::vector<T> & appendedTo, const std::vector<T> & appended)
    {
	appendedTo.insert(end(appendedTo), begin(appended), end(appended));
    }

    template<typename T>
    void union_sorted(std::vector<T> *v1, std::vector<T> &v2)
    {
	std::vector<T> output;
	output.reserve(v1->size() + v2.size());
	std::merge(v1->begin(), v1->end(), v2.begin(), v2.end(), std::back_inserter(output));
	auto last = std::unique(output.begin(), output.end());
	output.erase(last, output.end());
	v1->swap(output);
    }

    template<typename T>
    void sort_and_union(std::vector<T> *v1, std::vector<T> &v2)
    {
	std::sort(v1->begin(), v1->end());
	std::sort(v2.begin(), v2.end());
	return union_sorted(v1, v2);
    }
}
