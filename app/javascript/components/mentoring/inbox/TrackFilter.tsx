import React from 'react'
import { useIsMounted } from 'use-is-mounted'
import { useRequestQuery, Request } from '../../../hooks/request-query'
import { Loading } from '../../common/Loading'
import { TrackList, Track } from './TrackList'

export const TrackFilter = ({
  request,
  value,
  setTrack,
}: {
  request: Request
  value: string | null
  setTrack: (track: string | null) => void
}): JSX.Element => {
  const isMountedRef = useIsMounted()
  const { isLoading, isError, data: tracks } = useRequestQuery<Track[]>(
    'track-filter',
    request,
    isMountedRef
  )
  return (
    <div className="c-track-filter">
      {isLoading && <Loading />}
      {isError && <p>Something went wrong</p>}
      {tracks && (
        <TrackList tracks={tracks} setTrack={setTrack} value={value} />
      )}
    </div>
  )
}
